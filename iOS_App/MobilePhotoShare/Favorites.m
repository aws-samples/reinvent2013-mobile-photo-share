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

#import "Favorites.h"
#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"
#import "Constants.h"
#import <AWSRuntime/AWSRuntime.h>
#import <AWSDynamoDB/AWSDynamoDB.h>

@implementation Favorites

+(void)addFavorite:(NSString*)imageUrl
{
    [self addFavoriteUsingDynamoDB:imageUrl];
}


+(NSSet*)getFavorites
{
    return [self getFavoritesUsingDynamoDB];
}

+(void)addFavoriteUsingDynamoDB:(NSString*)imageUrl
{
    NSSet* favorites = [Favorites getFavorites];

    if ( [favorites containsObject:imageUrl] == NO ) {
        DynamoDBPutItemRequest *putItemRequest = [DynamoDBPutItemRequest new];
        putItemRequest.tableName = DYNAMODB_TABLENAME;

        DynamoDBAttributeValue *userId = [[DynamoDBAttributeValue alloc] initWithS:[AmazonKeyChainWrapper userId]];
        DynamoDBAttributeValue *newFavorites = [DynamoDBAttributeValue new];
        [newFavorites.sS addObjectsFromArray:[favorites allObjects]];
        [newFavorites.sS addObject:imageUrl];

        [putItemRequest.item setValue:userId forKey:@"UserId"];
        [putItemRequest.item setValue:newFavorites forKey:@"Favorites"];

        [[[AmazonClientManager sharedInstance] ddb] putItem:putItemRequest];
    }
}

+(NSSet*)getFavoritesUsingDynamoDB
{
    DynamoDBAttributeValue *userId = [[DynamoDBAttributeValue alloc] initWithS:[AmazonKeyChainWrapper userId]];
     
    DynamoDBGetItemRequest *getItemRequest = [DynamoDBGetItemRequest new];
    getItemRequest.tableName = DYNAMODB_TABLENAME;
    getItemRequest.key = [NSMutableDictionary dictionaryWithObject:userId forKey:@"UserId"];
    getItemRequest.consistentRead = YES;
    
    DynamoDBGetItemResponse *getItemResponse = [[[AmazonClientManager sharedInstance] ddb] getItem:getItemRequest];
    DynamoDBAttributeValue  *favorites = [getItemResponse.item valueForKey:@"Favorites"];
     
    return [NSSet setWithArray:favorites.sS];
}

@end
