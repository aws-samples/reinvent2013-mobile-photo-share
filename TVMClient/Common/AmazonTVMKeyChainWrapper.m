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

#import "AmazonTVMKeyChainWrapper.h"


NSString *kKeychainAccessKeyIdentifier;
NSString *kKeychainSecretKeyIdentifier;
NSString *kKeychainSecrutiyTokenIdentifier;
NSString *kKeychainExpirationDateIdentifier;

NSString *kKeychainUsernameIdentifier;
NSString *kKeychainUidIdentifier;
NSString *kKeychainKeyIdentifier;


@implementation AmazonTVMKeyChainWrapper

+(void)initialize {
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    kKeychainAccessKeyIdentifier = [NSString stringWithFormat:@"%@.AWSAccessKey", bundleID];
    kKeychainSecretKeyIdentifier= [NSString stringWithFormat:@"%@.AWSSecretKey", bundleID];
    kKeychainSecrutiyTokenIdentifier  = [NSString stringWithFormat:@"%@.AWSSecurityToken", bundleID];
    kKeychainExpirationDateIdentifier = [NSString stringWithFormat:@"%@.AWSExpirationDate", bundleID];
    
    kKeychainUsernameIdentifier = [NSString stringWithFormat:@"%@.USERNAME", bundleID];
    kKeychainUidIdentifier = [NSString stringWithFormat:@"%@.UID", bundleID]; 
    kKeychainKeyIdentifier = [NSString stringWithFormat:@"%@.KEY", bundleID];
}

+(bool)areCredentialsExpired
{
    AMZLogDebug(@"areCredentialsExpired");
    
    NSString *expiration = [AmazonTVMKeyChainWrapper getValueFromKeyChain:kKeychainExpirationDateIdentifier];
    if (expiration == nil) {
        return YES;
    }
    else {
        NSDate *expirationDate = [AmazonTVMKeyChainWrapper convertStringToDate:expiration];
        
        AMZLog(@"expirationDate : %@, %@", expiration, expirationDate);
        
        return [AmazonTVMKeyChainWrapper isExpired:expirationDate];
    }
}

+(void)registerDeviceId:(NSString *)uid andKey:(NSString *)key
{
    [AmazonTVMKeyChainWrapper storeValueInKeyChain:uid forKey:kKeychainUidIdentifier];
    [AmazonTVMKeyChainWrapper storeValueInKeyChain:key forKey:kKeychainKeyIdentifier];
}

+(NSString *)getKeyForDevice
{
    return [AmazonTVMKeyChainWrapper getValueFromKeyChain:kKeychainKeyIdentifier];
}

+(NSString *)getUidForDevice
{
    return [AmazonTVMKeyChainWrapper getValueFromKeyChain:kKeychainUidIdentifier];
}

+(void)storeUsername:(NSString *)theUsername
{
    [AmazonTVMKeyChainWrapper storeValueInKeyChain:theUsername forKey:kKeychainUsernameIdentifier];
}

+(NSString *)username
{
    return [AmazonTVMKeyChainWrapper getValueFromKeyChain:kKeychainUsernameIdentifier];
}

+(AmazonCredentials *)getCredentialsFromKeyChain
{
    NSString *accessKey     = [AmazonTVMKeyChainWrapper getValueFromKeyChain:kKeychainAccessKeyIdentifier];
    NSString *secretKey     = [AmazonTVMKeyChainWrapper getValueFromKeyChain:kKeychainSecretKeyIdentifier];
    NSString *securityToken = [AmazonTVMKeyChainWrapper getValueFromKeyChain:kKeychainSecrutiyTokenIdentifier];
    
    if ((accessKey != nil) && (secretKey != nil) && (securityToken != nil)) {
        if (![AmazonTVMKeyChainWrapper areCredentialsExpired]) {
            AmazonCredentials *credentials = [[AmazonCredentials alloc] initWithAccessKey:accessKey withSecretKey:secretKey];
            credentials.securityToken = securityToken;
            
            return credentials;
        }
    }
    
    return nil;
}

+(void)storeCredentialsInKeyChain:(NSString *)theAccessKey secretKey:(NSString *)theSecretKey securityToken:(NSString *)theSecurityToken expiration:(NSString *)theExpirationDate
{
    [AmazonTVMKeyChainWrapper storeValueInKeyChain:theAccessKey forKey:kKeychainAccessKeyIdentifier];
    [AmazonTVMKeyChainWrapper storeValueInKeyChain:theSecretKey forKey:kKeychainSecretKeyIdentifier];
    [AmazonTVMKeyChainWrapper storeValueInKeyChain:theSecurityToken forKey:kKeychainSecrutiyTokenIdentifier];
    [AmazonTVMKeyChainWrapper storeValueInKeyChain:theExpirationDate forKey:kKeychainExpirationDateIdentifier];
}

+(bool)isExpired:(NSDate *)date
{
    NSDate *soon = [NSDate dateWithTimeIntervalSinceNow:(15 * 60)];  // Fifteen minutes from now.
    
    if ( [soon compare:date] == NSOrderedDescending) {
        return YES;
    }
    else {
        return NO;
    }
}

+(NSDate *)convertStringToDate:(NSString *)expiration
{
    if (expiration != nil)
    {
        long long exactSecondOfExpiration = (long long)([expiration longLongValue] / 1000);
        return [[NSDate alloc] initWithTimeIntervalSince1970:exactSecondOfExpiration];
    }
    else
    {
        return nil;
    }
}

+(NSString *)getValueFromKeyChain:(NSString *)key
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

+(void)storeValueInKeyChain:(NSString *)value forKey:(NSString *)key
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

+(OSStatus)wipeKeyChain
{
    OSStatus keychainError = [AmazonTVMKeyChainWrapper wipeCredentialsFromKeyChain];
    
    if(keychainError != errSecSuccess)
    {
        return keychainError;
    }
    
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonTVMKeyChainWrapper createKeychainDictionaryForKey:kKeychainUidIdentifier]);
    
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound)
    {
        AMZLogDebug(@"Keychain Key: kKeychainUidIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonTVMKeyChainWrapper createKeychainDictionaryForKey : kKeychainKeyIdentifier]);
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound)
    {
        AMZLogDebug(@"Keychain Key: kKeychainKeyIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    return errSecSuccess;
}

+(OSStatus)wipeCredentialsFromKeyChain
{
    OSStatus keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonTVMKeyChainWrapper createKeychainDictionaryForKey : kKeychainAccessKeyIdentifier]);
    
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound)
    {
        AMZLogDebug(@"Keychain Key: kKeychainAccessKeyIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonTVMKeyChainWrapper createKeychainDictionaryForKey : kKeychainSecretKeyIdentifier]);
    
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound)
    {
        AMZLogDebug(@"Keychain Key: kKeychainSecretKeyIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonTVMKeyChainWrapper createKeychainDictionaryForKey : kKeychainSecrutiyTokenIdentifier]);
    
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound)
    {
        AMZLogDebug(@"Keychain Key: kKeychainSecrutiyTokenIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonTVMKeyChainWrapper createKeychainDictionaryForKey : kKeychainExpirationDateIdentifier]);
    
    if(keychainError != errSecSuccess && keychainError != errSecItemNotFound) 
    {
        AMZLogDebug(@"Keychain Key: kKeychainExpirationDateIdentifier, Error Code: %ld", keychainError);
        return keychainError;
    }
    
    return errSecSuccess;
}

+(NSMutableDictionary *)createKeychainDictionaryForKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrGeneric];
    [dictionary setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [dictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrAccount];
    [dictionary setObject:(__bridge id) kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    return dictionary;
}

@end
