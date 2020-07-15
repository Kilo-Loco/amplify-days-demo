//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCore
import AWSPluginsCore
import AppSyncRealTimeClient

final public class AWSGraphQLSubscriptionOperation<R: Decodable>: GraphQLSubscriptionOperation<R> {

    let pluginConfig: AWSAPICategoryPluginConfiguration
    let subscriptionConnectionFactory: SubscriptionConnectionFactory
    let authService: AWSAuthServiceBehavior

    var subscriptionConnection: SubscriptionConnection?
    var subscriptionItem: SubscriptionItem?

    init(request: GraphQLOperationRequest<R>,
         pluginConfig: AWSAPICategoryPluginConfiguration,
         subscriptionConnectionFactory: SubscriptionConnectionFactory,
         authService: AWSAuthServiceBehavior,
         inProcessListener: AWSGraphQLSubscriptionOperation.InProcessListener?,
         resultListener: AWSGraphQLSubscriptionOperation.ResultListener?) {

        self.pluginConfig = pluginConfig
        self.subscriptionConnectionFactory = subscriptionConnectionFactory
        self.authService = authService

        super.init(categoryType: .api,
                   eventName: HubPayload.EventName.API.subscribe,
                   request: request,
                   inProcessListener: inProcessListener,
                   resultListener: resultListener)
    }

    override public func cancel() {
        if let subscriptionItem = subscriptionItem, let subscriptionConnection = subscriptionConnection {
            subscriptionConnection.unsubscribe(item: subscriptionItem)
            let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.disconnected)
            dispatchInProcess(data: subscriptionEvent)
            dispatch(result: .successfulVoid)
            finish()
        } else {
            super.cancel()
        }
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        // Validate the request
        do {
            try request.validate()
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("Could not validate request", "", nil)))
            finish()
            return
        }

        // Retrieve endpoint configuration
        let endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig
        do {
            endpointConfig = try pluginConfig.endpoints.getConfig(for: request.apiName, endpointType: .graphQL)
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("Could not get endpoint configuration", "", nil)))
            finish()
            return
        }

        // Retrieve the subscription connection
        do {
            subscriptionConnection = try subscriptionConnectionFactory.getOrCreateConnection(for: endpointConfig,
                                                                                             authService: authService)
        } catch {
            let error = APIError.operationError("Unable to get connection for api \(endpointConfig.name)", "", error)
            dispatch(result: .failure(error))
            finish()
            return
        }

        // Create subscription

        subscriptionItem = subscriptionConnection?.subscribe(requestString: request.document,
                                                             variables: request.variables,
                                                             eventHandler: { [weak self] event, _ in
            self?.onAsyncSubscriptionEvent(event: event)
        })

    }

    private func onAsyncSubscriptionEvent(event: SubscriptionItemEvent) {
        switch event {
        case .connection(let subscriptionConnectionEvent):
            onSubscriptionEvent(subscriptionConnectionEvent)
        case .data(let data):
            onGraphQLResponseData(data)
        case .failed(let error):
            dispatch(result: .failure(APIError.operationError("subscription item event failed with error", "", error)))
            finish()
        }
    }

    private func onSubscriptionEvent(_ subscriptionConnectionEvent: SubscriptionConnectionEvent) {
        switch subscriptionConnectionEvent {
        case .connecting:
            let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.connecting)
            dispatchInProcess(data: subscriptionEvent)
        case .connected:
            let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.connected)
            dispatchInProcess(data: subscriptionEvent)
        case .disconnected:
            let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(.disconnected)
            dispatchInProcess(data: subscriptionEvent)
            dispatch(result: .successfulVoid)
            finish()
        }
    }

    private func onSubscriptionConnectionState(_ subscriptionConnectionState: SubscriptionConnectionState) {
        let subscriptionEvent = SubscriptionEvent<GraphQLResponse<R>>.connection(subscriptionConnectionState)
        dispatchInProcess(data: subscriptionEvent)

        if case .disconnected = subscriptionConnectionState {
            dispatch(result: .successfulVoid)
            finish()
        }
    }

    private func onGraphQLResponseData(_ graphQLResponseData: Data) {
        do {
            let graphQLServiceResponse = try GraphQLResponseDecoder.deserialize(graphQLResponse: graphQLResponseData)
            let graphQLResponse = try GraphQLResponseDecoder.decode(graphQLServiceResponse: graphQLServiceResponse,
                                                                    responseType: request.responseType,
                                                                    decodePath: request.decodePath,
                                                                    rawGraphQLResponse: graphQLResponseData)
            dispatchInProcess(data: .data(graphQLResponse))
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
        } catch {
            // TODO: Verify with the team that terminating a subscription after failing to decode/cast one
            // payload is the right thing to do. Another option would be to propagate a GraphQL error, but
            // leave the subscription alive.
            dispatch(result: .failure(APIError.operationError("Failed to deserialize", "", error)))
            finish()
        }
    }

}
