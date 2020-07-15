//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthConfirmSignInRequest {

    func hasError() -> AuthError? {
        guard !challengeResponse.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.confirmSignUpUsernameError.field,
                                               AuthPluginErrorConstants.confirmSignUpUsernameError.errorDescription,
                                               AuthPluginErrorConstants.confirmSignUpUsernameError.recoverySuggestion)
        }
        return nil
    }
}
