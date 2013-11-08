## Running the MobilePhotoShare Sample App

This is a sample mobile application that demonstrates how a number of AWS Tools and Services can work together to create a fully functioning iOS Application. The MobilePhotoShare App allows users to do the following:
   
   * Allow users to login using Facebook.
   * Upload photos to Amazon S3 using the S3 Transfer Manager.
   * Mark photos as public.  Public photos are visible by all App users.
   * Geo-tag photos using the Geo Library for DynamoDB.
   * Add photos to a list of "Favorites" using Amazon DynamoDB.
   * Register their device to recieve Push Notifications using SNS Mobile Push.


### Steps to run the sample

1.  Download the [AWS SDK for iOS](http://aws.amazon.com/sdkforios).  
1.  Create a Facebook Application by following these [instructions](documents/Facebook Setup.md).
1.  Create the AWS DynamoDB Table to store users Favorites by following these [instructions](documents/CLI-DynamoDB.md).  
1.  Run a [Cloud Formation template](documents/CloudFormation.md) to setup the necessary AWS resources for the App.
1.  Get the iOS App running by following these [instructions](documents/App Setup.md). 

