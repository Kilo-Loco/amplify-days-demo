//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias RawGraphQLResponse = String

public typealias GraphQLResponse<ResponseType: Decodable> =
    Result<ResponseType, GraphQLResponseError<ResponseType>>

/// An error response from a GraphQL API
public enum GraphQLResponseError<ResponseType: Decodable>: AmplifyError {

    /// An error response. The associated value will be an array of GraphQLError objects that contain service-specific
    /// error messages. https://graphql.github.io/graphql-spec/June2018/#sec-Errors
    case error([GraphQLError])

    /// A partially-successful response. The `ResponseType` associated value will contain as much of the payload as the
    /// service was able to fulfill, and the errors will be an array of GraphQLError that contain service-specific error
    /// messages.
    case partial(ResponseType, [GraphQLError])

    /// A successful, or partially-successful response from the server that could not be transformed into the specified
    /// response type. The RawGraphQLResponse contains the entire response from the service, including data and errors.
    case transformationError(RawGraphQLResponse, APIError)

    public var errorDescription: ErrorDescription {
        switch self {
        case .error(let errors):
            return "GraphQL service returned a successful response containing errors: \(errors)"
        case .partial(_, let errors):
            return "GraphQL service returned a partially-successful response containing errors: \(errors)"
        case .transformationError:
            return "Failed to decode GraphQL response to the `ResponseType` \(String(describing: ResponseType.self))"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .error:
            return "The list of `GraphQLError` contains service-specific messages"
        case .partial:
            return "The list of `GraphQLError` contains service-specific messages."
        case .transformationError:
            return """
            Failed to transform to `ResponseType`.
            Take a look at the `RawGraphQLResponse` and underlying error to see where it failed to decode.
            """
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .error:
            return nil
        case .partial:
            return nil
        case .transformationError(_, let error):
            return error
        }
    }
}
