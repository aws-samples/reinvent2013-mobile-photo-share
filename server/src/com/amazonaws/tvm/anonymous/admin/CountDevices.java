package com.amazonaws.tvm.anonymous.admin;

public class CountDevices extends BaseAdmin {

    public static void main(String[] args) {
        String awsAccessKeyID = System.getProperty(AWSAccessKeyID);
        String awsSecretKey = System.getProperty(AWSSecretKey);
        String deviceTable = System.getProperty("DeviceTable");

        if (awsAccessKeyID == null || awsSecretKey == null || deviceTable == null) {
            System.out
                    .println("Usage:java CountDevices -DAWS_ACCESS_KEY_ID=<access_key> -DAWS_SECRET_KEY=<secret_key> -DDeviceTable=<table_name>");
            return;
        }

        CountDevices obj = new CountDevices(awsAccessKeyID, awsSecretKey);

        if (!obj.doesTableExist(deviceTable)) {
            System.err.println("Invalid user table : " + deviceTable);
            return;
        }

        System.out.println("The number of users = " + obj.countDevices(deviceTable));

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
