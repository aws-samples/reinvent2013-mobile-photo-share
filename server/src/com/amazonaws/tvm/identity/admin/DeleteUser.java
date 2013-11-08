package com.amazonaws.tvm.identity.admin;

import java.util.HashMap;

import com.amazonaws.services.dynamodbv2.model.AttributeValue;
import com.amazonaws.services.dynamodbv2.model.DeleteItemRequest;

public class DeleteUser extends BaseAdmin {

    public static void main(String[] args) {
        String awsAccessKeyID = System.getProperty(AWSAccessKeyID);
        String awsSecretKey = System.getProperty(AWSSecretKey);
        String userTable = System.getProperty("UserTable");

        if (awsAccessKeyID == null || awsSecretKey == null || userTable == null
                || args.length == 0 || args[0].length() == 0) {
            System.err
                    .println("Usage:java DeleteUser -DAWS_ACCESS_KEY_ID=<access_key> -DAWS_SECRET_KEY=<secret_key> -DUserTable=<table_name> <username_to_be_deleted>");
            return;
        }

        DeleteUser obj = new DeleteUser(awsAccessKeyID, awsSecretKey);

        if (!obj.doesTableExist(userTable)) {
            System.err.println("Invalid user table : " + userTable);
            return;
        }

        String username = args[0];
        obj.deleteUser(username, userTable);
        System.out.println(String.format("User [%s] deleted successfully", username));
    }

    public DeleteUser(String awsAccessKeyID, String awsSecretKey) {
        super(awsAccessKeyID, awsSecretKey);
    }

    /**
     * Deletes the specified username from the user table.
     */
    public void deleteUser(String username, String table) {
        HashMap<String, AttributeValue> key = new HashMap<String, AttributeValue>();
        key.put("username", new AttributeValue().withS(username));

        DeleteItemRequest deleteItemRequest = new DeleteItemRequest()
                .withTableName(table)
                .withKey(key);

        ddb.deleteItem(deleteItemRequest);
    }
}
