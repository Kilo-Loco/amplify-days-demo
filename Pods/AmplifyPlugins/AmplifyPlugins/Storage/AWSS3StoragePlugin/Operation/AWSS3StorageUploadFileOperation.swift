//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSS3

public class AWSS3StorageUploadFileOperation: AmplifyInProcessReportingOperation<
    StorageUploadFileRequest,
    Progress,
    String,
    StorageError
>, StorageUploadFileOperation {

    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior

    var storageTaskReference: StorageTaskReference?

    /// Serial queue for synchronizing access to `storageTaskReference`.
    private let storageTaskActionQueue = DispatchQueue(label: "com.amazonaws.amplify.StorageTaskActionQueue")

    init(_ request: StorageUploadFileRequest,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         progressListener: InProcessListener?,
         resultListener: ResultListener?) {

        self.storageService = storageService
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.uploadFile,
                   request: request,
                   inProcessListener: progressListener,
                   resultListener: resultListener)
    }

    override public func pause() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.pause()
            super.pause()
        }
    }

    override public func resume() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.resume()
            super.resume()
        }
    }

    override public func cancel() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.cancel()
            super.cancel()
        }
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        if let error = request.validate() {
            dispatch(error)
            finish()
            return
        }

        let identityIdResult = authService.getIdentityId()
        guard case let .success(identityId) = identityIdResult else {
            if case let .failure(error) = identityIdResult {
                dispatch(StorageError.authError(error.errorDescription, error.recoverySuggestion, error))
            }

            finish()
            return
        }

        let uploadSize: UInt64
        do {
            uploadSize = try StorageRequestUtils.getSize(request.local)
        } catch let error as StorageError {
            dispatch(error)
            finish()
            return
        } catch {
            dispatch(StorageError.unknown(error.localizedDescription, error))
            finish()
            return
        }

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.options.accessLevel,
                                                           identityId: identityId,
                                                           key: request.key)
        let serviceMetadata = StorageRequestUtils.getServiceMetadata(request.options.metadata)

        if isCancelled {
            finish()
            return
        }

        if uploadSize > StorageUploadFileRequest.Options.multiPartUploadSizeThreshold {
            storageService.multiPartUpload(serviceKey: serviceKey,
                                           uploadSource: .local(request.local),
                                           contentType: request.options.contentType,
                                           metadata: serviceMetadata) { [weak self] event in
                                               self?.onServiceEvent(event: event)
                                           }
        } else {
            storageService.upload(serviceKey: serviceKey,
                                  uploadSource: .local(request.local),
                                  contentType: request.options.contentType,
                                  metadata: serviceMetadata) { [weak self] event in
                                      self?.onServiceEvent(event: event)
                                  }
        }
    }

    private func onServiceEvent(
        event: StorageEvent<StorageTaskReference, Progress, Void, StorageError>) {
        switch event {
        case .initiated(let reference):
            storageTaskActionQueue.async {
                self.storageTaskReference = reference
                if self.isCancelled {
                    self.storageTaskReference?.cancel()
                    self.finish()
                }
            }
        case .inProcess(let progress):
            dispatch(progress)
        case .completed:
            dispatch(request.key)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        dispatchInProcess(data: progress)
    }

    private func dispatch(_ result: String) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: StorageError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
