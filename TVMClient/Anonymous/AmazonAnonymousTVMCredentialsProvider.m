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

#import "AmazonAnonymousTVMCredentialsProvider.h"
#import "AmazonAnonymousTVMClient.h"
#import "AmazonTVMKeyChainWrapper.h"
#import "GetTokenResponse.h"

@interface AmazonAnonymousTVMCredentialsProvider ()

@property (nonatomic, strong) AmazonAnonymousTVMClient *tvm;
@property (nonatomic, strong) AmazonCredentials        *tvmCredentials;
@property (nonatomic, strong) NSDate                   *expiration;
@property (nonatomic, strong) NSError                  *error;

@end


@implementation AmazonAnonymousTVMCredentialsProvider

@synthesize tvm=_tvm;
@synthesize tvmCredentials=_tvmCredentials;
@synthesize expiration=_expiration;
@synthesize error=_error;

-(AmazonCredentials *)credentials
{
    if ((self.tvmCredentials == nil) || ([self isExpired])) {
        [self refresh];
    }
    return self.tvmCredentials;
}

-(void)refresh {
    @synchronized(self) {
        AMZLogDebug(@"Refreshing credentials from TVM.");
        self.tvmCredentials = nil;
        self.expiration = nil;
        
        @try {
            GetTokenResponse *tvmResponse = (GetTokenResponse *)[self.tvm getToken];
            
            // request failed
            if ([tvmResponse wasSuccessful]) {
            
                
                self.tvmCredentials = [[AmazonCredentials alloc] initWithAccessKey:tvmResponse.accessKey
                                                                      withSecretKey:tvmResponse.secretKey
                                                                  withSecurityToken:tvmResponse.securityToken];
                
                self.expiration = [NSDate dateWithISO8061Format:tvmResponse.expirationDate];
            }
            else {
                AMZLog(@"Error refreshing credentials");
                //self.error = response.error;
            }
        }
        
        // If exceptions are enabled, catch it here
        @catch (AmazonServiceException *exception) {
            AMZLog(@"Error refreshing credentials: %@", exception);
            
            // store the error for later
            self.error = [AmazonErrorHandler errorFromException:exception];
        }
    }
}

-(BOOL)isExpired
{
    @synchronized(self) {
        NSDate *soon = [NSDate dateWithTimeIntervalSinceNow:(self.refreshThreshold)];
        if ( [soon compare:self.expiration] == NSOrderedDescending) {
            return YES;
        }
        else {
            return NO;
        }
    }
}
-(id)initWithEndpoint:(NSString *)endPoint
{
    AmazonAnonymousTVMClient *tvm = [[AmazonAnonymousTVMClient alloc] initWithEndpoint:endPoint useSSL:NO];
    return [self initWithClient:tvm];
}

-(id)initWithClient:(AmazonAnonymousTVMClient *)theClient
{
    self = [super init];
    if (self) {
        self.tvm = theClient;
        
        // check to see if device is registered
        if ([AmazonTVMKeyChainWrapper getKeyForDevice] == nil) {
            [self.tvm anonymousRegister];
        }
    }
    return self;
}



@end
