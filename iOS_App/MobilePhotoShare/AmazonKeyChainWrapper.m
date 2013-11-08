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
#import "AmazonKeyChainWrapper.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSSecurityTokenService/AWSSecurityTokenService.h>

NSString *kKeychainProviderIdentifier;
NSString *kKeychainUserIDIdentifier;

@implementation AmazonKeyChainWrapper

+ (void)initialize 
{
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;

    kKeychainProviderIdentifier = [NSString stringWithFormat:@"%@.IDENITYPROVIDER", bundleID];
    kKeychainUserIDIdentifier = [NSString stringWithFormat:@"%@.USERID", bundleID];
}

+ (void)storeIdentityProvider:(NSString *)theProvider andUserID:(NSString *)userId
{
    [AmazonKeyChainWrapper storeValueInKeyChain:theProvider forKey:kKeychainProviderIdentifier];
    [AmazonKeyChainWrapper storeValueInKeyChain:userId forKey:kKeychainUserIDIdentifier];
}

+ (NSString *)identityProvider
{
    return [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainProviderIdentifier];
}

+ (NSString *)userId
{
    return [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainUserIDIdentifier];
}

+ (NSString *)getValueFromKeyChain:(NSString *)key
{
    AMZLogDebug(@"Get Value for KeyChain key:[%@]", key);
    
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    
    [queryDictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
    [queryDictionary setObject:(id) kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    [queryDictionary setObject:(__bridge id) kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [queryDictionary setObject:(id) kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [queryDictionary setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    CFDictionaryRef cfQueryDictionary = (__bridge_retained CFDictionaryRef)queryDictionary;
    CFDictionaryRef cfReturnedDictionary = NULL;
    OSStatus keychainError = SecItemCopyMatching(cfQueryDictionary, (CFTypeRef *)&cfReturnedDictionary);
    CFRelease(cfQueryDictionary);
    NSDictionary *returnedDictionary = (__bridge_transfer NSDictionary *)cfReturnedDictionary;
    
    if (keychainError == noErr)
    {
        NSData *rawData = [returnedDictionary objectForKey:(__bridge id)kSecValueData];
        return [[NSString alloc] initWithBytes:[rawData bytes] length:[rawData length] encoding:NSUTF8StringEncoding];
    }
    else
    {
        AMZLogDebug(@"Unable to fetch value for keychain key '%@', Error Code: %ld", key, keychainError);
        return nil;
    }
}

+ (void)storeValueInKeyChain:(NSString *)value forKey:(NSString *)key
{
    AMZLogDebug(@"Storing value:[%@] in KeyChain as key:[%@]", value, key);
    
    NSMutableDictionary *keychainDictionary = [[NSMutableDictionary alloc] init];
    [keychainDictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrGeneric];
    [keychainDictionary setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [keychainDictionary setObject:[value dataUsingEncoding:NSUTF8StringEncoding]    forKey:(__bridge id)kSecValueData];
    [keychainDictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrAccount];
    [keychainDictionary setObject:(__bridge id) kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    OSStatus keychainError = SecItemAdd((__bridge CFDictionaryRef)keychainDictionary, NULL);
    if (keychainError == errSecDuplicateItem) {
        SecItemDelete((__bridge CFDictionaryRef)keychainDictionary);
        keychainError = SecItemAdd((__bridge CFDictionaryRef)keychainDictionary, NULL);
    }
    
    
    if (keychainError != errSecSuccess) {
        AMZLogDebug(@"Error saving value to keychain key '%@', Error Code: %ld", key, keychainError);
    }
}

+ (OSStatus)wipeKeyChain
{
    OSStatus keychainError  = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey:kKeychainProviderIdentifier]);
    
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound)
    {
        AMZLogDebug(@"Keychain Key: kKeychainProviderIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    keychainError  = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey:kKeychainUserIDIdentifier]);
    
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound)
    {
        AMZLogDebug(@"Keychain Key: kKeychainUserIDIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    return errSecSuccess;
}

+ (NSMutableDictionary *)createKeychainDictionaryForKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrGeneric];
    [dictionary setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [dictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrAccount];
    [dictionary setObject:(__bridge id) kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    return dictionary;
}

@end
