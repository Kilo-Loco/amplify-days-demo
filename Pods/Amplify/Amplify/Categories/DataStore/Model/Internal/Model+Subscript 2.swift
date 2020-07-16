//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Implement dynamic access to properties of a `Model`.
///
/// ```swift
/// let id = model["id"]
/// ```
extension Model {

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public subscript(_ key: String) -> Any?? {
        let mirror = Mirror(reflecting: self)
        let firstChild = mirror.children.first { $0.label == key }
        guard let property = firstChild else {
            return nil
        }

        // Special case for properties that have optional values. Child.property is Any rather than Any?, and we want
        // callers to receive a `.some(nil)` (indicating that the property exists, but has a `nil` value) rather than a
        // bare `nil` (indicating the property doesn't exist). This matches how Swift handles dictionary subscripting
        if case Optional<Any>.none = property.value {
            return .some(nil)
        } else {
            return property.value
        }
    }
}
