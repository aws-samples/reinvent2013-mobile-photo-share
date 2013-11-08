//
//  AmazonAnonymousTVMCredentialsProvider.h
//  TVMClient
//
//  Created by Kinney, Earl on 10/2/13.
//  Copyright (c) 2013 Amazon Web Services. All rights reserved.
//

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
