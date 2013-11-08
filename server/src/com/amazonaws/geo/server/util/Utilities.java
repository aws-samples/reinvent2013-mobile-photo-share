package com.amazonaws.geo.server.util;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;

import com.amazonaws.ClientConfiguration;
import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.geo.GeoDataManager;
import com.amazonaws.geo.GeoDataManagerConfiguration;
import com.amazonaws.geo.model.GeoPoint;
import com.amazonaws.geo.model.PutPointRequest;
import com.amazonaws.geo.util.GeoTableUtil;
import com.amazonaws.regions.Region;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClient;
import com.amazonaws.services.dynamodbv2.model.AttributeValue;
import com.amazonaws.services.dynamodbv2.model.CreateTableRequest;
import com.amazonaws.services.dynamodbv2.model.DescribeTableRequest;
import com.amazonaws.services.dynamodbv2.model.DescribeTableResult;
import com.amazonaws.services.dynamodbv2.model.ResourceNotFoundException;

public class Utilities {
	private static Utilities utilities;

	public enum Status {
		NOT_STARTED, CREATING_TABLE, INSERTING_DATA_TO_TABLE, READY
	}

	private Status status = Status.NOT_STARTED;
	private GeoDataManager geoDataManager;

	public static synchronized Utilities getInstance() {
		if (utilities == null) {
			utilities = new Utilities();
		}

		return utilities;
	}

	public Status getStatus() {
		return status;
	}

	public boolean isAccessKeySet() {
		String accessKey = System.getProperty("AWS_ACCESS_KEY_ID");
		return accessKey != null && accessKey.length() > 0;
	}

	public boolean isSecretKeySet() {
		String secretKey = System.getProperty("AWS_SECRET_KEY");
		return secretKey != null && secretKey.length() > 0;
	}

	public void setupTable() {
		setupGeoDataManager();

		GeoDataManagerConfiguration config = geoDataManager.getGeoDataManagerConfiguration();
		DescribeTableRequest describeTableRequest = new DescribeTableRequest().withTableName(config.getTableName());

		try {
			config.getDynamoDBClient().describeTable(describeTableRequest);

			if (status == Status.NOT_STARTED) {
				status = Status.READY;
			}
		} catch (ResourceNotFoundException e) {
			PhotoLocationsTable photoLocationsTable = new PhotoLocationsTable();
			photoLocationsTable.start();
		}

	}

	public synchronized GeoDataManager setupGeoDataManager() {
		if (geoDataManager == null) {
			String accessKey = getSystemProperty( "AWS_ACCESS_KEY_ID" ); 
			String secretKey = getSystemProperty( "AWS_SECRET_KEY" );
			String regionName = getSystemProperty( "PARAM2", "us-east-1" ); 
			String tableName = getSystemProperty( "PARAM3", "PhotoLocations" );

			AWSCredentials credentials = new BasicAWSCredentials(accessKey, secretKey);
			AmazonDynamoDBClient ddb = new AmazonDynamoDBClient(credentials);
			Region region = Region.getRegion(Regions.fromName(regionName));
			ddb.setRegion(region);

			GeoDataManagerConfiguration config = new GeoDataManagerConfiguration(ddb, tableName);
			geoDataManager = new GeoDataManager(config);
		}

		return geoDataManager;
	}

	private class PhotoLocationsTable extends Thread {
		public void run() {
			status = Status.CREATING_TABLE;

			GeoDataManagerConfiguration config = geoDataManager.getGeoDataManagerConfiguration();

			CreateTableRequest createTableRequest = GeoTableUtil.getCreateTableRequest(config);
			config.getDynamoDBClient().createTable(createTableRequest);

			waitForTableToBeReady();
		}

		private void waitForTableToBeReady() {
			GeoDataManagerConfiguration config = geoDataManager.getGeoDataManagerConfiguration();

			DescribeTableRequest describeTableRequest = new DescribeTableRequest().withTableName(config.getTableName());
			DescribeTableResult describeTableResult = config.getDynamoDBClient().describeTable(describeTableRequest);

			while (!describeTableResult.getTable().getTableStatus().equalsIgnoreCase("ACTIVE")) {
				try {
					Thread.sleep(2000);
				} catch (InterruptedException e) {
					throw new RuntimeException(e);
				}
				describeTableResult = config.getDynamoDBClient().describeTable(describeTableRequest);
			}
		}
	}

    public static String getSystemProperty( String property ) {
        return getSystemProperty( property, null );
    }

	public static String getSystemProperty( String property, String defaultValue ) {
		String value = System.getProperty( property ); 
		if ( isEmpty( value ) ) {
			return defaultValue;
		}
		else {
			return value;
		}
	}

	private static boolean isEmpty(String str) {
        if (null == str || str.trim().length() == 0)
            return true;
        return false;
    }


	private Utilities() {}
}
