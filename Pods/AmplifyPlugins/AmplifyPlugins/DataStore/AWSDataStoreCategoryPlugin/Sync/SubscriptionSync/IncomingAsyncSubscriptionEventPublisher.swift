//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

/// Collects all subscription types for a given model into a single subscribable publisher.
///
/// The queue "Element" is AnyModel to allow for queues to be collected into an aggregate structure upstream, but each
/// individual EventQueue operates on a single, specific Model type.
///
/// At initialization, the Queue sets up subscriptions, via the provided `APICategoryGraphQLBehavior`, for each type
/// `GraphQLSubscriptionType` and holds a reference to the returned operation. The operations' listeners enqueue
/// incoming successful events onto a `Publisher`, that queue processors can subscribe to.
@available(iOS 13.0, *)
final class IncomingAsyncSubscriptionEventPublisher: Cancellable {
    typealias Payload = MutationSync<AnyModel>
    typealias Event = SubscriptionEvent<GraphQLResponse<Payload>>

    private var onCreateOperation: GraphQLSubscriptionOperation<Payload>?
    private var onCreateValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onCreateConnected: Bool

    private var onUpdateOperation: GraphQLSubscriptionOperation<Payload>?
    private var onUpdateValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onUpdateConnected: Bool

    private var onDeleteOperation: GraphQLSubscriptionOperation<Payload>?
    private var onDeleteValueListener: GraphQLSubscriptionOperation<Payload>.InProcessListener?
    private var onDeleteConnected: Bool

    private let connectionStatusQueue: OperationQueue
    private var combinedConnectionStatusIsConnected: Bool {
        return onCreateConnected && onUpdateConnected && onDeleteConnected
    }

    private let incomingSubscriptionEvents: PassthroughSubject<Event, DataStoreError>

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior, auth: AuthCategoryBehavior?) {
        self.onCreateConnected = false
        self.onUpdateConnected = false
        self.onDeleteConnected = false
        self.connectionStatusQueue = OperationQueue()
        connectionStatusQueue.name
            = "com.amazonaws.Amplify.RemoteSyncEngine.\(modelType.modelName).IncomingAsyncSubscriptionEventPublisher"
        connectionStatusQueue.maxConcurrentOperationCount = 1
        connectionStatusQueue.isSuspended = false

        let incomingSubscriptionEvents = PassthroughSubject<Event, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents

        let onCreateValueListener = onCreateValueListenerHandler(event:)
        self.onCreateValueListener = onCreateValueListener
        self.onCreateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onCreate,
            api: api,
            auth: auth,
            valueListener: onCreateValueListener,
            completionListener: genericCompletionListenerHandler(result:)
        )

        let onUpdateValueListener = onUpdateValueListenerHandler(event:)
        self.onUpdateValueListener = onUpdateValueListener
        self.onUpdateOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onUpdate,
            api: api,
            auth: auth,
            valueListener: onUpdateValueListener,
            completionListener: genericCompletionListenerHandler(result:)
        )

        let onDeleteValueListener = onDeleteValueListenerHandler(event:)
        self.onDeleteValueListener = onDeleteValueListener
        self.onDeleteOperation = IncomingAsyncSubscriptionEventPublisher.apiSubscription(
            for: modelType,
            subscriptionType: .onDelete,
            api: api,
            auth: auth,
            valueListener: onDeleteValueListener,
            completionListener: genericCompletionListenerHandler(result:)
        )
    }

    func onCreateValueListenerHandler(event: Event) {
        log.verbose("onCreateValueListener: \(event)")
        let onCreateConnectionOp = CancelAwareBlockOperation {
            self.onCreateConnected = self.isConnectionStatusConnected(for: event)
            self.sendConnectionEventIfConnected(event: event)
        }
        genericValueListenerHandler(event: event, cancelAwareBlock: onCreateConnectionOp)
    }

    func onUpdateValueListenerHandler(event: Event) {
        log.verbose("onUpdateValueListener: \(event)")
        let onUpdateConnectionOp = CancelAwareBlockOperation {
            self.onUpdateConnected = self.isConnectionStatusConnected(for: event)
            self.sendConnectionEventIfConnected(event: event)
        }
        genericValueListenerHandler(event: event, cancelAwareBlock: onUpdateConnectionOp)
    }

    func onDeleteValueListenerHandler(event: Event) {
        log.verbose("onDeleteValueListener: \(event)")
        let onDeleteConnectionOp = CancelAwareBlockOperation {
            self.onDeleteConnected = self.isConnectionStatusConnected(for: event)
            self.sendConnectionEventIfConnected(event: event)
        }
        genericValueListenerHandler(event: event, cancelAwareBlock: onDeleteConnectionOp)
    }

    func isConnectionStatusConnected(for event: Event) -> Bool {
        if case .connection(.connected) = event {
            return true
        }
        return false
    }

    func sendConnectionEventIfConnected(event: Event) {
        if combinedConnectionStatusIsConnected {
            incomingSubscriptionEvents.send(event)
        }
    }

    func genericValueListenerHandler(event: Event, cancelAwareBlock: CancelAwareBlockOperation) {
        if case .connection = event {
            connectionStatusQueue.addOperation(cancelAwareBlock)
        } else {
            incomingSubscriptionEvents.send(event)
        }
    }

    func genericCompletionListenerHandler(result: Result<Void, APIError>) {
        switch result {
        case .success:
            incomingSubscriptionEvents.send(completion: .finished)
        case .failure(let apiError):
            let dataStoreError = DataStoreError(error: apiError)
            incomingSubscriptionEvents.send(completion: .failure(dataStoreError))
        }
    }

    static func apiSubscription(
        for modelType: Model.Type,
        subscriptionType: GraphQLSubscriptionType,
        api: APICategoryGraphQLBehavior,
        auth: AuthCategoryBehavior?,
        valueListener: @escaping GraphQLSubscriptionOperation<Payload>.InProcessListener,
        completionListener: @escaping GraphQLSubscriptionOperation<Payload>.ResultListener
    ) -> GraphQLSubscriptionOperation<Payload> {

        let request: GraphQLRequest<Payload>
        if let auth = auth, modelType.schema.hasAuthenticationRules, let user = auth.getCurrentUser() {
            // TODO: check model schema for identityClaim to figure out which is the ownerId field coming from
            // https://github.com/aws-amplify/amplify-ios/issues/485
            request = GraphQLRequest<Payload>.subscription(to: modelType,
                                                           subscriptionType: subscriptionType,
                                                           ownerId: user.username)
        } else {
            request = GraphQLRequest<Payload>.subscription(to: modelType, subscriptionType: subscriptionType)
        }

        let operation = api.subscribe(request: request,
                                      valueListener: valueListener,
                                      completionListener: completionListener)
        return operation
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == Event, S.Failure == DataStoreError {
        incomingSubscriptionEvents.subscribe(subscriber)
    }

    func cancel() {
        genericCompletionListenerHandler(result: .successfulVoid)

        onCreateOperation?.cancel()
        onCreateOperation = nil
        onCreateValueListener = nil

        onUpdateOperation?.cancel()
        onUpdateOperation = nil
        onUpdateValueListener = nil

        onDeleteOperation?.cancel()
        onDeleteOperation = nil
        onDeleteValueListener = nil

        connectionStatusQueue.cancelAllOperations()
    }

    func reset(onComplete: () -> Void) {
        onCreateOperation?.cancel()
        onCreateOperation = nil
        onCreateValueListener?(.connection(.disconnected))

        onUpdateOperation?.cancel()
        onUpdateOperation = nil
        onUpdateValueListener?(.connection(.disconnected))

        onDeleteOperation?.cancel()
        onDeleteOperation = nil
        onDeleteValueListener?(.connection(.disconnected))

        genericCompletionListenerHandler(result: .successfulVoid)

        onComplete()
    }

}

@available(iOS 13.0, *)
extension IncomingAsyncSubscriptionEventPublisher: DefaultLogger { }
