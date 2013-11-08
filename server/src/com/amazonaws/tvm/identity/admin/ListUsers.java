package com.amazonaws.tvm.identity.admin;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.amazonaws.services.dynamodbv2.model.AttributeValue;
import com.amazonaws.services.dynamodbv2.model.ScanRequest;
import com.amazonaws.services.dynamodbv2.model.ScanResult;

public class ListUsers extends BaseAdmin {

    public static void main(String[] args) {
        String awsAccessKeyID = System.getProperty(AWSAccessKeyID);
        String awsSecretKey = System.getProperty(AWSSecretKey);
        String userTable = System.getProperty("UserTable");

        if (awsAccessKeyID == null || awsSecretKey == null || userTable == null) {
            System.err
                    .println("Usage:java CountUsers -DAWS_ACCESS_KEY_ID=<access_key> -DAWS_SECRET_KEY=<secret_key> -DUserTable=<table_name>");
            return;
        }

        ListUsers obj = new ListUsers(awsAccessKeyID, awsSecretKey);

        if (!obj.doesTableExist(userTable)) {
            System.err.println("Invalid user table : " + userTable);
            return;
        }

        for (String username : obj.listUsers(userTable)) {
            System.out.println(username);
        }
    }

    public ListUsers(String awsAccessKeyID, String awsSecretKey) {
        super(awsAccessKeyID, awsSecretKey);
    }

    /**
     * Returns the list of usernames stored in the user table.
     */
    public List<String> listUsers(String userTable) {
        List<String> users = new ArrayList<String>(1000);

        ScanResult result = ddb.scan(new ScanRequest().withTableName(userTable).withLimit(1000));

        for (Map<String, AttributeValue> item : result.getItems()) {
            users.add(item.get("username").getS());
        }

        return users;
    }
}
