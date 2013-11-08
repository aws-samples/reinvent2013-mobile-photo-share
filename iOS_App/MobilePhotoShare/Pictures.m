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

#import "Pictures.h"

#import "Constants.h"
#import "AmazonClientManager.h"
#import <AWSS3/AWSS3.h>

@implementation Pictures


+(void)uploadPicture:(NSData*)data key:(NSString*)key delegate:(id<AmazonServiceRequestDelegate>)delegate
{
//    [self uploadPictureUsingS3:data key:key delegate:delegate];
    [self uploadPictureUsingTM:data key:key delegate:delegate];
}

+(void)downloadPicture:(NSString*)filePath key:(NSString*)key delegate:(id<AmazonServiceRequestDelegate>)delegate
{
//    [self downloadPictureUsingS3:filePath key:key delegate:delegate];
    [self downloadPictureUsingTM:filePath key:key delegate:delegate];
}


//----------------------------------------------
// uploadPicture
//----------------------------------------------
+(void)uploadPictureUsingS3:(NSData*)data key:(NSString*)key delegate:(id<AmazonServiceRequestDelegate>)delegate
{
    // This code would be a lot larger and more complicated to do a multi-part upload.
    // Any failure will cause the entire upload to start from the beginning again.
    S3PutObjectRequest *uploadRequest = [[S3PutObjectRequest alloc] initWithKey:key inBucket:BUCKET_NAME];
    uploadRequest.data = data;
    uploadRequest.delegate = delegate;
     
    [[[AmazonClientManager sharedInstance] s3] putObject:uploadRequest];
}

+(void)uploadPictureUsingTM:(NSData*)data key:(NSString*)key delegate:(id<AmazonServiceRequestDelegate>)delegate
{
    [[AmazonClientManager sharedInstance] transferManager].delegate = delegate;
    [[[AmazonClientManager sharedInstance] transferManager] uploadData:data bucket:BUCKET_NAME key:key];
}


//----------------------------------------------
// downloadPicture
//----------------------------------------------
+(void)downloadPictureUsingS3:(NSString*)filePath key:(NSString*)key delegate:(id<AmazonServiceRequestDelegate>)delegate
{
    // Would be difficult to pause, resume or cancel the request.
    // Any failure will cause the entire download to start from the beginning again.
    S3GetObjectRequest *getRequest = [S3GetObjectRequest new];
    getRequest.delegate = delegate;
    getRequest.bucket = BUCKET_NAME;
    getRequest.key = key;
     
    [[[AmazonClientManager sharedInstance] s3] getObject:getRequest];
}

+(void)downloadPictureUsingTM:(NSString*)filePath key:(NSString*)key delegate:(id<AmazonServiceRequestDelegate>)delegate
{
    [[AmazonClientManager sharedInstance] transferManager].delegate = delegate;
    [[[AmazonClientManager sharedInstance] transferManager] downloadFile:filePath bucket:BUCKET_NAME key:key];
}

@end
