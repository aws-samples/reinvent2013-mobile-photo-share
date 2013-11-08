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

package com.amazonaws.tvm.identity.admin;

public class CountDevices extends BaseAdmin {

    public static void main(String[] args) {
        String awsAccessKeyID = System.getProperty(AWSAccessKeyID);
        String awsSecretKey = System.getProperty(AWSSecretKey);
        String deviceTable = System.getProperty("DeviceTable");

        if (awsAccessKeyID == null || awsSecretKey == null || deviceTable == null) {
            System.err
                    .println("Usage:java CountDevices -DAWS_ACCESS_KEY_ID=<access_key> -DAWS_SECRET_KEY=<secret_key> -DDeviceTable=<table_name>");
            return;
        }

        CountDevices obj = new CountDevices(awsAccessKeyID, awsSecretKey);

        if (!obj.doesTableExist(deviceTable)) {
            System.err.println("Invalid device table : " + deviceTable);
            return;
        }

        System.out.println("The number of devices = " + obj.countDevices(deviceTable));
    }

    public CountDevices(String awsAccessKeyID, String awsSecretKey) {
        super(awsAccessKeyID, awsSecretKey);
    }

    /**
     * Returns the list of devices stored in the device table.
     */
    public long countDevices(String deviceTable) {
        return getTableCount(deviceTable);
    }

}
