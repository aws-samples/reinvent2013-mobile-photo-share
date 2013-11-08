## Create the Amazon DynamoDB table 


### Using the AWS CLI to create your table

1. Install and setup the [AWS Command Line Interface](http://aws.amazon.com/cli/).
2. Run this command to create your table:
   * Creates a table called ***Favorites*** in the **us-west-2** region.

	```
aws --region us-west-2 dynamodb create-table --table-name Favorites --key-schema AttributeName=UserId,KeyType=HASH --attribute-definitions AttributeName=UserId,AttributeType=S --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
	```

### Using the AWS Management Console to create your table

1. Log into the DynamoDB console in the [AWS Management Console](https://console.aws.amazon.com/dynamodb/home?region=us-west-2).
1. Click **Create Table**.
1. Enter **Favorites** for the table name.
1. Click **Hash** for the **Primary Key Type**
1. Enter **UserId** as *String* for the **Hash Attribute Name**.
1. Click **Continue**
1. Click **Continue** on the **Add Indexes** scren.
1. Click **Continue** on the **Provisioned Throughput Capacity** screen.
1. Uncheck **Use Basic Alarms** on the **Throughput Alarms** screen and then click **Continue**. 
1. Click **Create**.
