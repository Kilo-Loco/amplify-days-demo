//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

//Used for testing:
@available(iOS 13.0, *)
typealias IncomingEventReconciliationQueueFactory =
    ([Model.Type],
    APICategoryGraphQLBehavior,
    StorageEngineAdapter,
    AuthCategoryBehavior?,
    ModelReconciliationQueueFactory?
) -> IncomingEventReconciliationQueue

@available(iOS 13.0, *)
final class AWSIncomingEventReconciliationQueue: IncomingEventReconciliationQueue {

    static let factory: IncomingEventReconciliationQueueFactory = { modelTypes, api, storageAdapter, auth, _ in
        AWSIncomingEventReconciliationQueue(modelTypes: modelTypes,
                                            api: api,
                                            storageAdapter: storageAdapter,
                                            auth: auth,
                                            modelReconciliationQueueFactory: nil)
    }
    private var modelReconciliationQueueSinks: [String: AnyCancellable]

    private let eventReconciliationQueueTopic: PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return eventReconciliationQueueTopic.eraseToAnyPublisher()
    }

    private let connectionStatusSerialQueue: DispatchQueue
    private var reconciliationQueues: [String: ModelReconciliationQueue]
    private var reconciliationQueueConnectionStatus: [String: Bool]
    private var modelReconciliationQueueFactory: ModelReconciliationQueueFactory

    init(modelTypes: [Model.Type],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter,
         auth: AuthCategoryBehavior? = nil,
         modelReconciliationQueueFactory: ModelReconciliationQueueFactory? = nil) {
        self.modelReconciliationQueueSinks = [:]
        self.eventReconciliationQueueTopic = PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>()
        self.reconciliationQueues = [:]
        self.reconciliationQueueConnectionStatus = [:]
        self.modelReconciliationQueueFactory = modelReconciliationQueueFactory ??
            AWSModelReconciliationQueue.init(modelType:storageAdapter:api:auth:incomingSubscriptionEvents:)
        //TODO: Add target for SyncEngine system to help prevent thread explosion and increase performance
        // https://github.com/aws-amplify/amplify-ios/issues/399
        self.connectionStatusSerialQueue
            = DispatchQueue(label: "com.amazonaws.DataStore.AWSIncomingEventReconciliationQueue")
        for modelType in modelTypes {
            let modelName = modelType.modelName
            let queue = self.modelReconciliationQueueFactory(modelType, storageAdapter, api, auth, nil)
            guard reconciliationQueues[modelName] == nil else {
                Amplify.DataStore.log
                    .warn("Duplicate model name found: \(modelName), not subscribing")
                continue
            }
            reconciliationQueues[modelName] = queue
            let modelReconciliationQueueSink = queue.publisher.sink(receiveCompletion: onReceiveCompletion(completed:),
                                                                    receiveValue: onReceiveValue(receiveValue:))
            modelReconciliationQueueSinks[modelName] = modelReconciliationQueueSink
        }
    }

    func start() {
        reconciliationQueues.values.forEach { $0.start() }
        eventReconciliationQueueTopic.send(.started)
    }

    func pause() {
        reconciliationQueues.values.forEach { $0.pause() }
        eventReconciliationQueueTopic.send(.paused)
    }

    func offer(_ remoteModel: MutationSync<AnyModel>) {
        guard let queue = reconciliationQueues[remoteModel.model.modelName] else {
            // TODO: Error handling
            return
        }

        queue.enqueue(remoteModel)
    }

    private func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        connectionStatusSerialQueue.async {
            self.reconciliationQueueConnectionStatus = [:]
        }
        switch completed {
        case .failure(let error):
            eventReconciliationQueueTopic.send(completion: .failure(error))
        case .finished:
            eventReconciliationQueueTopic.send(completion: .finished)
        }
    }

    private func onReceiveValue(receiveValue: ModelReconciliationQueueEvent) {
        switch receiveValue {
        case .mutationEvent(let event):
            eventReconciliationQueueTopic.send(.mutationEvent(event))
        case .connected(let modelName):
            connectionStatusSerialQueue.async {
                self.reconciliationQueueConnectionStatus[modelName] = true
                if self.reconciliationQueueConnectionStatus.count == self.reconciliationQueues.count {
                    self.eventReconciliationQueueTopic.send(.initialized)
                }
            }
        default:
            break
        }
    }

    func cancel() {
        modelReconciliationQueueSinks.values.forEach { $0.cancel() }
        reconciliationQueues.values.forEach { $0.cancel()}
        connectionStatusSerialQueue.async {
            self.reconciliationQueues = [:]
            self.modelReconciliationQueueSinks = [:]
        }
    }
}

@available(iOS 13.0, *)
extension AWSIncomingEventReconciliationQueue: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()
        for queue in reconciliationQueues.values {
            guard let queue = queue as? Resettable else {
                continue
            }
            group.enter()
            DispatchQueue.global().async {
                queue.reset { group.leave() }
            }
        }
        group.wait()
        onComplete()
    }

}
