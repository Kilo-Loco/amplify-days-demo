//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public enum AWSAPICategoryPluginError {
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension AWSAPICategoryPluginError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _, _):
            return errorDescription
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _):
            return recoverySuggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError):
            return underlyingError
        }
    }
}
