//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Reachability
import Combine

@available(iOS 13.0, *)
class NetworkReachabilityNotifier {
    private var reachability: NetworkReachabilityProviding?
    private var allowsCellularAccess = true

    let reachabilityPublisher = PassthroughSubject<ReachabilityUpdate, Never>()
    var publisher: AnyPublisher<ReachabilityUpdate, Never> {
        return reachabilityPublisher.eraseToAnyPublisher()
    }

    public init(host: String,
                allowsCellularAccess: Bool,
                reachabilityFactory: NetworkReachabilityProvidingFactory.Type) throws {
        self.reachability = reachabilityFactory.make(for: host)
        self.allowsCellularAccess = allowsCellularAccess

        // Add listener for Reachability and start its notifier
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(respondToReachabilityChange),
                                               name: .reachabilityChanged,
                                               object: nil)
        do {
            try reachability?.startNotifier()
        } catch {
            throw error
        }
    }

    deinit {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self)
        reachabilityPublisher.send(completion: Subscribers.Completion<Never>.finished)
    }

    // MARK: - Notifications
    @objc private func respondToReachabilityChange() {
        guard let reachability = reachability else {
            return
        }

        let isReachable: Bool
        switch reachability.connection {
        case .wifi:
            isReachable = true
        case .cellular:
            isReachable = allowsCellularAccess
        case .none, .unavailable:
            isReachable = false
        }

        let reachabilityMessageUpdate = ReachabilityUpdate(isOnline: isReachable)
        reachabilityPublisher.send(reachabilityMessageUpdate)
    }

}

// MARK: - Reachability
extension Reachability: NetworkReachabilityProvidingFactory {
    public static func make(for hostname: String) -> NetworkReachabilityProviding? {
        return try? Reachability(hostname: hostname)
    }
}

extension Reachability: NetworkReachabilityProviding { }
