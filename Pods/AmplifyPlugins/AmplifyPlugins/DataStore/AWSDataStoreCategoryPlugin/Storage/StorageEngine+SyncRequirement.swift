//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

extension StorageEngine {

    func startSync() {
        guard let api = tryGetAPIPlugin() else {
            log.info("Unable to find suitable API plugin for syncEngine. syncEngine will not be started")
            return
        }

        let authPluginRequired = requiresAuthPlugin()

        guard authPluginRequired else {
            syncEngine?.start(api: api, auth: nil)
            return
        }

        guard let auth = tryGetAuthPlugin() else {
            log.warn("Unable to find suitable Auth plugin for syncEngine. Models require auth")
            return
        }

        syncEngine?.start(api: api, auth: auth)
    }

    private func tryGetAPIPlugin() -> APICategoryGraphQLBehavior? {
        do {
            return try Amplify.API.getPlugin(for: validAPIPluginKey)
        } catch {
            return nil
        }
    }

    private func tryGetAuthPlugin() -> AuthCategoryBehavior? {
        do {
            return try Amplify.Auth.getPlugin(for: validAuthPluginKey)
        } catch {
            return nil
        }
    }

    private func requiresAuthPlugin() -> Bool {
        let containsAuthEnabledSyncableModels = ModelRegistry.models.contains {
            $0.schema.isSyncable && $0.schema.hasAuthenticationRules
        }

        return containsAuthEnabledSyncableModels
    }
}
