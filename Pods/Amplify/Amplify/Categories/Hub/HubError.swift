//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors associated with configuring and inspecting Amplify Categories
public enum HubError {
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
    case unknownError(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension HubError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let description, _, _),
             .unknownError(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _),
             .unknownError(_, let recoverySuggestion, _):
            return recoverySuggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError),
             .unknownError(_, _, let underlyingError):
            return underlyingError
        }
    }
}
