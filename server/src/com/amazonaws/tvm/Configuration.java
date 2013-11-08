/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package com.amazonaws.tvm;

import java.util.logging.Logger;

import com.amazonaws.AmazonClientException;
import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.regions.RegionUtils;
import com.amazonaws.services.identitymanagement.AmazonIdentityManagementClient;

/**
 * This class captures all of the configuration settings. These environment
 * properties are defined in the BeanStalk container configuration tab.
 */
public class Configuration {

    protected static final Logger log = TokenVendingMachineLogger.getLogger();

    /**
     * The AWS Access Key Id for the AWS account from which to generate
     * sessions.
     */
    public static final String AWS_ACCESS_KEY_ID = Utilities.getSystemProperty("AWS_ACCESS_KEY_ID"); 

    /**
     * The AWS Secret Key for the AWS account from which to generate sessions.
     */
    public static final String AWS_SECRET_KEY = Utilities.getSystemProperty("AWS_SECRET_KEY"); 

    /**
     * The AWS Account Id for the AWS account from which to generate sessions.
     */
    public static final String AWS_ACCOUNT_ID = getAWSAccountID();

    /**
     * The application name
     */
    public static final String APP_NAME = getAppName();

    /**
     * The duration for which the session is valid. Default is 24 hours = 86400
     * secs
     */
    public static final String SESSION_DURATION = "86400";

    /**
     * The DynamoDB endpoint to connect to.
     */
    public static final String DYNAMODB_ENDPOINT = getDynamoDBEndpoint();

    /**
     * The DynamoDB region the user table is stored.
     */
    public static final String DYNAMODB_REGION = getDynamoDBRegion();

    /**
     * The name of the DynamoDB Table used to store user info if using the
     * custome authentication mechanisms.
     */
    public static final String USERS_TABLE = getUsersTable();

    /**
     * The name of the DynamoDB Table used to store device info if using the
     * custome authentication mechanisms.
     */
    public static final String DEVICE_TABLE = getDeviceTable();

    private static String getAppName() {
        return Utilities.getSystemProperty("PARAM1", "MyMobileAppName").toLowerCase();
    }

    private static String getUsersTable() {
        return "MobilePhotoShareIdentity_" + APP_NAME + "_USERS";
    }

    private static String getDeviceTable() {
        return "MobilePhotoShareIdentity_" + APP_NAME + "_DEVICES";
    }

    private static String getAWSAccountID() {
        try {
            String accessKey = AWS_ACCESS_KEY_ID;
            String secretKey = AWS_SECRET_KEY;

            if (Utilities.isEmpty(accessKey) || Utilities.isEmpty(secretKey)) {
                return null;
            }

            AWSCredentials creds = new BasicAWSCredentials(accessKey, secretKey);
            AmazonIdentityManagementClient iam = new AmazonIdentityManagementClient(creds);
            return iam.getUser().getUser().getArn().split(":")[4];
        } catch (AmazonClientException e) {
            throw new RuntimeException("Failed to get AWS account id", e);
        }
    }

    private static String getDynamoDBEndpoint() {
        System.setProperty("com.amazonaws.sdk.disableCertChecking", "true");
        return "dynamodb." + getDynamoDBRegion() + ".amazonaws.com";
    }

    private static String getDynamoDBRegion() {
        return Utilities.getSystemProperty("PARAM2", "us-east-1");
    }
}
