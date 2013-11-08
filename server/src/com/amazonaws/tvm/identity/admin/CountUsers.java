package com.amazonaws.tvm.identity.admin;

public class CountUsers extends BaseAdmin {

    public static void main(String[] args) {
        String awsAccessKeyID = System.getProperty(AWSAccessKeyID);
        String awsSecretKey = System.getProperty(AWSSecretKey);
        String userTable = System.getProperty("UserTable");

        if (awsAccessKeyID == null || awsSecretKey == null || userTable == null) {
            System.err
                    .println("Usage:java CountUsers -DAWS_ACCESS_KEY_ID=<access_key> -DAWS_SECRET_KEY=<secret_key> -DUserTable=<table_name>");
            return;
        }

        CountUsers obj = new CountUsers(awsAccessKeyID, awsSecretKey);

        if (!obj.doesTableExist(userTable)) {
            System.err.println("Invalid user table : " + userTable);
            return;
        }

        System.out.println("The number of users = " + obj.countUsers(userTable));
    }

    public CountUsers(String awsAccessKeyID, String awsSecretKey) {
        super(awsAccessKeyID, awsSecretKey);
    }

    /**
     * Returns the list of usernames stored in the user table.
     */
    public long countUsers(String userTable) {
        return getTableCount(userTable);
    }

}
