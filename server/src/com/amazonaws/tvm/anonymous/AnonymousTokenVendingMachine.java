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

import java.util.logging.Logger;

import com.amazonaws.services.securitytoken.model.Credentials;

import com.amazonaws.tvm.Configuration;
import com.amazonaws.tvm.Utilities;
import com.amazonaws.tvm.TokenVendingMachineLogger;

import com.amazonaws.tvm.anonymous.DeviceAuthentication.DeviceInfo;

import com.amazonaws.tvm.anonymous.exception.DataAccessException;
import com.amazonaws.tvm.anonymous.exception.UnauthorizedException;

/**
 * This class implements functions for Anonymous mode. It allows to register new
 * devices and specify the encryption key to be used for this device in future
 * communication. This class allows a registered device to make token request.
 * The request is validated using signature and granted tokens if signature is
 * valid. The tokens are encrypted using the key corresponding to the device UID
 * so that it can be decrypted back by the same device only.
 */
public class AnonymousTokenVendingMachine {

    public static final Logger log = TokenVendingMachineLogger.getLogger();

    private final DeviceAuthentication authenticator;
    private final TemporaryCredentialManagement credentialManagement;

    public AnonymousTokenVendingMachine() {
        authenticator = new DeviceAuthentication();
        credentialManagement = new TemporaryCredentialManagement();
    }

    /**
     * Verify if the given signature is valid.
     * 
     * @param stringToSign
     *            The string to sign
     * @param key
     *            The key used in the signature process
     * @param signature
     *            Base64 encoded HMAC-SHA256 signature derived from key and
     *            string
     * @return true if computed signature matches with the given signature,
     *         false otherwise
     */
    public boolean validateSignature(String stringToSign, String key, String targetSignature) {
        String computedSignature = Utilities.sign(stringToSign, key);
        return Utilities.slowStringComparison(targetSignature, computedSignature);
    }

    /**
     * Verify if the token request is valid. UID is authenticated. The timestamp
     * is checked to see it falls within the valid timestamp window. The
     * signature is computed and matched against the given signature. Useful in
     * Anonymous and Identity modes
     * 
     * @param uid
     *            Unique device identifier
     * @param signature
     *            Base64 encoded HMAC-SHA256 signature derived from key and
     *            timestamp
     * @param timestamp
     *            Timestamp of the request in ISO8601 format
     * @throws DataAccessException
     * @throws UnauthorizedException
     */
    public void validateTokenRequest(String uid, String signature, String timestamp) throws DataAccessException,
            UnauthorizedException {
        if (!Utilities.isTimestampValid(timestamp)) {
            throw new UnauthorizedException("Invalid timestamp: " + timestamp);
        }
        log.info(String.format("Timestamp [ %s ] is valid", timestamp));

        DeviceInfo device = authenticator.getDeviceInfo(uid);
        if (device == null) {
            throw new UnauthorizedException("Couldn't find device: " + uid);
        }

        if (!validateSignature(timestamp, device.getKey(), signature)) {
            throw new UnauthorizedException("Invalid signature: " + signature);
        }
        log.info("Signature matched!!!");
    }

    /**
     * Generate tokens for given UID. The tokens are encrypted using the key
     * corresponding to UID. Encrypted tokens are then wrapped in JSON object
     * before returning it. Useful in Anonymous and Identity modes
     * 
     * @param uid
     *            Unique device identifier
     * @return encrypted tokens as JSON object
     * @throws DataAccessException
     * @throws UnauthorizedException
     */
    public String getToken(String uid) throws DataAccessException, UnauthorizedException {
        DeviceInfo device = authenticator.getDeviceInfo(uid);
        if (device == null) {
            throw new UnauthorizedException("Couldn't find device: " + uid);
        }

        log.info("Creating temporary credentials");
        Credentials sessionCredentials = credentialManagement.getTemporaryCredentials(uid);

        log.info("Generating session tokens for UID : " + uid);
        return Utilities.prepareJsonResponseForTokens(sessionCredentials, device.getKey());
    }

    /**
     * Allows user device (e.g. mobile) to register with Token Vending Machine
     * (TVM). This function is useful in Anonymous mode
     * 
     * @param uid
     *            Unique device identifier
     * @param key
     *            Secret piece of information
     * @return status code indicating if the registration was successful or not
     * @throws DataAccessException
     */
    public boolean registerDevice(String uid, String key) throws DataAccessException {
        return authenticator.registerDevice(uid, key);
    }

}
