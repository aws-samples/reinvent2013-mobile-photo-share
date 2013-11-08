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

package com.amazonaws.tvm.anonymous;

import com.amazonaws.AmazonClientException;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.securitytoken.AWSSecurityTokenServiceClient;
import com.amazonaws.services.securitytoken.model.Credentials;
import com.amazonaws.services.securitytoken.model.GetFederationTokenRequest;

import com.amazonaws.tvm.anonymous.exception.DataAccessException;

import com.amazonaws.tvm.Utilities;
import com.amazonaws.tvm.Configuration;

/**
 * This class retrieves temporary federation token, i.e. session credentials,
 * from Amazon Security Token Service.
 */
public class TemporaryCredentialManagement {

    private final AWSSecurityTokenServiceClient sts;

    public TemporaryCredentialManagement() {
        BasicAWSCredentials creds = new BasicAWSCredentials(Configuration.AWS_ACCESS_KEY_ID,
                Configuration.AWS_SECRET_KEY);
        sts = new AWSSecurityTokenServiceClient(creds);
    }

    /**
     * Retrieves temporary credentials for the given user.
     * 
     * @param username
     *            a given user name
     * @return temporary AWS credentials
     * @throws DataAccessException
     *             When it fails to get federation token from STS
     */
    public Credentials getTemporaryCredentials(String username) throws DataAccessException {
        GetFederationTokenRequest getFederationTokenRequest = new GetFederationTokenRequest();
        getFederationTokenRequest.setName(username);
        getFederationTokenRequest.setPolicy(getPolicyObject());
        getFederationTokenRequest.setDurationSeconds(new Integer(Configuration.SESSION_DURATION));

        try {
            return sts.getFederationToken(getFederationTokenRequest).getCredentials();
        } catch (AmazonClientException e) {
            throw new DataAccessException("Failed to get federation token for user: " + username, e);
        }
    }

    protected String getPolicyObject() {
        return Utilities.getRawPolicyFile( "/AnonymousTokenVendingMachinePolicy.json" ).replaceAll("__REGION__", Configuration.DYNAMODB_REGION)
                .replaceAll("__ACCOUNT_ID__", Configuration.AWS_ACCOUNT_ID)
                .replaceAll("__DEVICE_TABLE__", Configuration.DEVICE_TABLE);
    }

}
