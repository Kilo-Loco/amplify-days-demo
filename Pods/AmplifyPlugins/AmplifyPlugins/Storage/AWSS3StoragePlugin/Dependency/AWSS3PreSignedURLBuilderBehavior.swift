//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

// Behavior that the implemenation class for AWSS3PreSignedURLBuilder will use.
protocol AWSS3PreSignedURLBuilderBehavior {

    // Returns a task for getting a pre signed URL
    func getPreSignedURL(_ getPreSignedURLRequest: AWSS3GetPreSignedURLRequest) -> AWSTask<NSURL>
}
