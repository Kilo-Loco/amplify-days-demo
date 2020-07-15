//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

public class AmplifyAWSServiceConfiguration: AWSServiceConfiguration {
    override public class func baseUserAgent() -> String! {
        //TODO: Retrieve this version from a centralized location:
        //https://github.com/aws-amplify/amplify-ios/issues/276
        let version = "1.0.4"
        let sdkName = "amplify-iOS"
        let systemName = UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
        let systemVersion = UIDevice.current.systemVersion
        let localeIdentifier = Locale.current.identifier
        return "\(sdkName)/\(version) \(systemName)/\(systemVersion) \(localeIdentifier)"
    }

    override public var userAgent: String {
        return AmplifyAWSServiceConfiguration.baseUserAgent()
    }

    override public func copy(with zone: NSZone? = nil) -> Any {
        return super.copy(with: zone)
    }

    override init() {
        super.init(region: .Unknown, credentialsProvider: nil)
    }

    override public init(region regionType: AWSRegionType,
                         credentialsProvider: AWSCredentialsProvider) {
        super.init(region: regionType, credentialsProvider: credentialsProvider)
    }

    public init(region regionType: AWSRegionType) {
        super.init(region: regionType, credentialsProvider: nil)
    }
}
