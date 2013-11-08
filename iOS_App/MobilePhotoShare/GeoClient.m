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

#import "GeoClient.h"
#import "Constants.h"
#import "AmazonClientManager.h"

@implementation GeoClient

+(void)storeGeoPoint:(CLLocation*)location userId:(NSString*)userId url:(NSString*)url title:(NSString*)title delegate:(NSObject*)delegate
{
    NSDictionary *requestDictionary = @{@"action" : @"put-point",
                                        @"request" : @{
                                                @"lat" : [NSNumber numberWithDouble:(location.coordinate.latitude + [GeoClient jitter])],
                                                @"lng" : [NSNumber numberWithDouble:(location.coordinate.longitude + [GeoClient jitter])],
                                                @"userId" : userId,
                                                @"s3-photo-url" : url,
                                                @"title" : title
                                                }
                                        };
    
    [GeoClient sendRequest:requestDictionary delegate:delegate];
}

+(void)query:(double)latitude longitude:(double)longitude userId:(NSString*)userId radius:(double)radius delegate:(NSObject*)delegate
{
    NSDictionary *requestDictionary = nil;
    requestDictionary = @{@"action" : @"query-radius",
                          @"request" : @{
                                  @"lat" : [NSNumber numberWithDouble:latitude],
                                  @"lng" : [NSNumber numberWithDouble:longitude],
                                  @"filterUserId" : [[AmazonClientManager sharedInstance] isLoggedIn] ? userId : @"",
                                  @"radiusInMeter" : [NSNumber numberWithDouble:radius]
                                  }
                          };

    [GeoClient sendRequest:requestDictionary delegate:delegate];
}

#pragma mark - Helper Functions

+(void)sendRequest:(NSDictionary *)requestDictionary delegate:(NSObject*)delegate
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/dynamodb-geo", SERVER_ENDPOINT]]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:120.0];
    
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                       options:kNilOptions
                                                         error:nil];
    request.HTTPMethod = @"POST";
    [[NSURLConnection alloc] initWithRequest:request delegate:delegate];
}

+(double)jitter
{
    double jitter = 0.0;
    int random = arc4random_uniform(100);
    if ( random % 2 == 0 ) {
        jitter = (double)((double)random/(double)12345);
    }
    else {
        jitter = (double)((double)random/(double)-13579);
    }
    
    return jitter;
}

@end
