package com.amazonaws.tvm.identity.admin;

import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;

import com.amazonaws.services.dynamodbv2.model.AttributeValue;
import com.amazonaws.services.dynamodbv2.model.GetItemRequest;

public class DescribeUser extends BaseAdmin {

    public static void main(String[] args) {
        String awsAccessKeyID = System.getProperty(AWSAccessKeyID);
        String awsSecretKey = System.getProperty(AWSSecretKey);
        String userTable = System.getProperty("UserTable");

        if (awsAccessKeyID == null || awsSecretKey == null || userTable == null
                || args.length == 0 || args[0].length() == 0) {
            System.err
                    .println("Usage:java DescribeUser -DAWS_ACCESS_KEY_ID=<access_key> -DAWS_SECRET_KEY=<secret_key> -DUserTable=<table_name> <username_to_be_described>");
            return;
        }

        DescribeUser obj = new DescribeUser(awsAccessKeyID, awsSecretKey);

        if (!obj.doesTableExist(userTable)) {
            System.err.println("Invalid user table : " + userTable);
            return;
        }

        String username = args[0];
        obj.describeUser(username, userTable);
    }

    public DescribeUser(String awsAccessKeyID, String awsSecretKey) {
        super(awsAccessKeyID, awsSecretKey);
    }

    /**
     * Returns the list of usernames stored in the user table.
     */
    public void describeUser(String username, String userTable) {
        HashMap<String, AttributeValue> key = new HashMap<String, AttributeValue>();
        key.put("username", new AttributeValue().withS(username));

        GetItemRequest getItemRequest = new GetItemRequest()
                .withTableName(userTable)
                .withKey(key);

        Map<String, AttributeValue> list = ddb.getItem(getItemRequest).getItem();
        if (list.isEmpty()) {
            System.err.println("No record found for username '" + username + "'");
            return;
        }

        for (Entry<String, AttributeValue> entry : list.entrySet()) {
            System.out.println(entry.getKey() + " = " + entry.getValue().getS());
        }
    }
}
