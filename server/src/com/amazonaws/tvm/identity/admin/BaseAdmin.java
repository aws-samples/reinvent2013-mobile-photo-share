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

import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClient;
import com.amazonaws.services.dynamodbv2.model.DescribeTableRequest;
import com.amazonaws.services.dynamodbv2.model.DescribeTableResult;
import com.amazonaws.services.dynamodbv2.model.ResourceNotFoundException;

public class BaseAdmin {

    protected final static String AWSAccessKeyID = "AWS_ACCESS_KEY_ID";
    protected final static String AWSSecretKey = "AWS_SECRET_KEY";

    protected AmazonDynamoDBClient ddb;

    public BaseAdmin(String awsAccessKeyID, String awsSecretKey) {
        ddb = new AmazonDynamoDBClient(new BasicAWSCredentials(awsAccessKeyID, awsSecretKey));
        ddb.setEndpoint("http://dynamodb.us-east-1.amazonaws.com");
    }

    protected long getTableCount(String tableName) {
        DescribeTableRequest request = new DescribeTableRequest().withTableName(tableName);
        DescribeTableResult result = ddb.describeTable(request);
        return result.getTable().getItemCount();
    }

    protected boolean doesTableExist(String tableName) {
        try {
            DescribeTableRequest request = new DescribeTableRequest().withTableName(tableName);
            DescribeTableResult result = ddb.describeTable(request);
            return (result != null && "ACTIVE".equals(result.getTable().getTableStatus()));
        } catch (ResourceNotFoundException e) {
            return false;
        }
    }

}
