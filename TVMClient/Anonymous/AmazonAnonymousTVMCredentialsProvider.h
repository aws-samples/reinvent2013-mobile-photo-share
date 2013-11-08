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

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>

@class AmazonAnonymousTVMClient;

/**
 * An implementation of AmazonCredentialsProvider which makes calls to an
 * anonymous Token Vending Machine (TVM)
 */

@interface AmazonAnonymousTVMCredentialsProvider : NSObject<AmazonCredentialsProvider>

/**
 * The threshold at which the credentials will be refreshed prior to their expiration
 * Defaults to 300 (5 minutes)
 */
@property (nonatomic, assign) NSInteger refreshThreshold;

/**
 * The last error (if any) that occured during refresh
 */
@property (readonly) NSError *error;

/** 
 * Inits the provider with information about the TVM
 *
 * @param endpoint the endpoint of the anonymous TVM
 */
-(id)initWithEndpoint:(NSString *)endPoint;

/** Inits the provider with a pre-configured client
 *
 * @param theClient The TVM client to use to make requests.
 */
-(id)initWithClient:(AmazonAnonymousTVMClient *)theClient;


@end
