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


#import "AmazonClientManager.h"

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AWSDynamoDB/AWSDynamoDB.h>
#import <AWSSNS/AWSSNS.h>
#import <AWSSecurityTokenService/AWSSecurityTokenService.h>

#import "Constants.h"
#import "AmazonKeyChainWrapper.h"
#import "AmazonAnonymousTVMCredentialsProvider.h"

@class AmazonWIFCredentialsProvider;

#define FB_PROVIDER             @"Facebook"
#define GOOGLE_PROVIDER         @"Google"
#define AMZN_PROVIDER           @"Amazon"
#define TVM_PROVIDER            @"TVM"
#define ANON_PROVIDER           @"Anonymous"


@interface AmazonClientManager()

@property (atomic, copy) LoginHandler callback;
@property (nonatomic, strong) AmazonS3Client *s3;
@property (nonatomic, strong) S3TransferManager *transferManager;
@property (nonatomic, strong) AmazonDynamoDBClient *ddb;
@property (nonatomic, strong) AmazonSNSClient *sns;
@property (nonatomic, strong) AmazonAnonymousTVMCredentialsProvider *anonProvider;
@property (nonatomic, strong) AmazonWIFCredentialsProvider *provider;

#if FB_LOGIN
@property (strong, nonatomic) FBSession *session;
#endif

#if GOOGLE_LOGIN
@property (strong, nonatomic) GTMOAuth2Authentication *auth;
#endif

@end

@implementation AmazonClientManager

+ (AmazonClientManager *)sharedInstance
{
    static AmazonClientManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AmazonClientManager new];
    });
    return sharedInstance;
}

- (BOOL)isAuthenticated
{
    return ([AmazonKeyChainWrapper identityProvider] != nil);
}

- (BOOL)isLoggedIn
{
    return ( [self isAuthenticated] && self.provider != nil);
}

- (void)initClients
{
    [AmazonLogger verboseLogging];
    
    if (self.provider != nil) {
        self.s3 = [[AmazonS3Client alloc] initWithCredentialsProvider:self.provider];
        self.ddb = [[AmazonDynamoDBClient alloc] initWithCredentialsProvider:self.provider];
        self.sns = [[AmazonSNSClient alloc] initWithCredentialsProvider:self.provider];
        self.transferManager = [S3TransferManager new];
        self.transferManager.s3 = self.s3;
    }
}

- (void)initAnonymousClients
{
    [AmazonKeyChainWrapper storeIdentityProvider:ANON_PROVIDER andUserID:ANON_PROVIDER];
    self.anonProvider = [[AmazonAnonymousTVMCredentialsProvider alloc] initWithEndpoint:SERVER_ENDPOINT];
    self.s3 = [[AmazonS3Client alloc] initWithCredentialsProvider:self.anonProvider];
    self.transferManager = [S3TransferManager new];
    self.transferManager.s3 = self.s3;
}

- (void)wipeAllCredentials
{
    @synchronized(self)
    {
        self.provider = nil;
        self.s3 = nil;
        self.transferManager = nil;
        [AmazonKeyChainWrapper wipeKeyChain];
    }
}

- (void)logoutWithCompletionHandler:(LoginHandler)completionHandler;
{
#if FB_LOGIN
    if ([[AmazonKeyChainWrapper identityProvider] isEqualToString:FB_PROVIDER]) {
        [self FBLogout];
    }
#endif
#if AMZN_LOGIN
    if ([[AmazonKeyChainWrapper identityProvider] isEqualToString:AMZN_PROVIDER]) {
        [self AMZNLogout];
    }
#endif
#if GOOGLE_LOGIN
    if ([[AmazonKeyChainWrapper identityProvider] isEqualToString:GOOGLE_PROVIDER]) {
        [self GoogleLogout];
    }
#endif
    
    [self wipeAllCredentials];
    [self initAnonymousClients];
    completionHandler(nil);
}


- (void)loginFromView:(UIView *)theView withCompletionHandler:(LoginHandler)completionHandler;
{
    self.callback = completionHandler;
    [[AmazonClientManager loginSheet] showInView:theView];
}


- (BOOL)handleOpenURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation
{
#if FB_LOGIN
    // attempt to extract a FB token from the url
    if ([self.session handleOpenURL:url]) {
        return YES;
    }
#endif
#if AMZN_LOGIN
    if ([AIMobileLib handleOpenURL:url sourceApplication:sourceApplication]) {
        return YES;
    }
#endif
#if GOOGLE_LOGIN
    // Handle Google+ sign-in button URL.
    if ([GPPURLHandler handleURL:url
               sourceApplication:sourceApplication
                      annotation:annotation]) {
        return YES;
    }
#endif
    return NO;
}

- (void)resumeSessionWithCompletionHandler:(LoginHandler)completionHandler
{
    NSString *provider = [AmazonKeyChainWrapper identityProvider];
    
    if ((provider == nil) || [provider isEqualToString:ANON_PROVIDER]) {
        [self initAnonymousClients];
        if (completionHandler != nil) {
            completionHandler(nil);
        }
        return;
    }
    
    self.callback = completionHandler;

#if FB_LOGIN
    if ([provider isEqualToString:FB_PROVIDER]) {
        [self reloadFBSession];
    }
#endif
#if AMZN_LOGIN
    if ([provider isEqualToString:AMZN_PROVIDER]) {
        [self AMZNLogin];
    }
#endif
#if GOOGLE_LOGIN
    if ([provider isEqualToString:GOOGLE_PROVIDER]) {
        [self reloadGSession];
    }
#endif
}

#pragma mark - UI Helpers

+ (UIActionSheet *)loginSheet
{
    return [[UIActionSheet alloc] initWithTitle:@"Choose Identity Provider"
                                       delegate:[AmazonClientManager sharedInstance]
                              cancelButtonTitle:@"Cancel"
                         destructiveButtonTitle:nil
                              otherButtonTitles:FB_PROVIDER, GOOGLE_PROVIDER, AMZN_PROVIDER, TVM_PROVIDER, nil];
}

+ (UIAlertView *)errorAlert:(NSString *)message
{
    return [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([buttonTitle isEqualToString:@"Cancel"]) {
        return;
    }
#if FB_LOGIN
    else if ([buttonTitle isEqualToString:FB_PROVIDER]) {
        [self FBLogin];
    }
#endif
#if AMZN_LOGIN
    else if ([buttonTitle isEqualToString:AMZN_PROVIDER]) {
        [self AMZNLogin];
    }
#endif
#if GOOGLE_LOGIN
    else if ([buttonTitle isEqualToString:GOOGLE_PROVIDER]) {
        [self GoogleLogin];
    }
#endif
    else {
        [[AmazonClientManager errorAlert:@"Provider not implemented"] show];
    }
}

- (void)attemptOfflineLogin {
    if([self.provider.error.domain isEqualToString:NSURLErrorDomain]
       && (self.provider.error.code == NSURLErrorNetworkConnectionLost ||
           self.provider.error.code == NSURLErrorTimedOut ||
           self.provider.error.code == NSURLErrorCannotFindHost ||
           self.provider.error.code == NSURLErrorCannotConnectToHost ||
           self.provider.error.code == NSURLErrorDNSLookupFailed ||
           self.provider.error.code == NSURLErrorNotConnectedToInternet ||
           self.provider.error.code == NSURLErrorBadServerResponse )
       && [self isAuthenticated])
    {
        // network error, initialize in offline mode with saved info
        [self initClients];
    }
    else {
        [[AmazonClientManager errorAlert:@"Unable to process login, check logs for further details"] show];
    }
}

#if FB_LOGIN
#pragma mark - Facebook

- (void)reloadFBSession
{
    if (!self.session.isOpen) {
        // create a fresh session object
        self.session = [FBSession new];

        // if we don't have a cached token, a call to open here would cause UX for login to
        // occur; we don't want that to happen unless the user clicks the login button, and so
        // we check here to make sure we have a token before calling open
        if (self.session.state == FBSessionStateCreatedTokenLoaded) {

            // even though we had a cached token, we need to login to make the session usable
            [self.session openWithCompletionHandler:^(FBSession *session,
                                                      FBSessionState status,
                                                      NSError *error) {
                if (error == nil) {
                    [self CompleteFBLogin];
                }
                else {
                    [[AmazonClientManager errorAlert:[NSString stringWithFormat:@"Error logging in with FB: %@", error.description]] show];
                }

            }];
        }
    }
}


- (void)CompleteFBLogin
{
    if (![self.session isOpen])
        return;
    
    self.provider = [[AmazonWIFCredentialsProvider alloc] initWithRole:FB_ROLE_ARN
                                                   andWebIdentityToken:self.session.accessTokenData.accessToken
                                                          fromProvider:@"graph.facebook.com"];

    // if we don't have an ID, we may need to initialize in offline mode
    if (self.provider.subjectFromWIF == nil) {
        [self attemptOfflineLogin];
    }
    // if we have an id, we are logged in
    else {
        NSLog(@"IDP id: %@", self.provider.subjectFromWIF);
        [AmazonKeyChainWrapper storeIdentityProvider:FB_PROVIDER andUserID:self.provider.subjectFromWIF];

        [self initClients];

        // set active session
        FBSession.activeSession = self.session;

        [FBRequestConnection
         startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                           id<FBGraphUser> user,
                                           NSError *error) {
             if (error) {
                 NSLog(@"Error loading username: %@", error);
             }
             else {
                 self.userName = user.name;
             }
         }];
    }

    if (self.callback) {
        self.callback(nil);
        self.callback = nil;
    }
}

- (void)FBLogin
{
    // session already open, exit
    if (self.session.isOpen) {
        [self CompleteFBLogin];
        return;
    }

    if (self.session == nil || self.session.state != FBSessionStateCreated) {
        // Create a new, logged out session.
        self.session = [FBSession new];
    }

    [self.session openWithCompletionHandler:^(FBSession *session,
                                              FBSessionState status,
                                              NSError *error) {
        if (error != nil) {
            [[AmazonClientManager errorAlert:[NSString stringWithFormat:@"Error logging in with FB: %@", error.description]] show];
        }
        else {
            [self CompleteFBLogin];
        }
    }];
    
}

- (void)FBLogout
{
    [self.session closeAndClearTokenInformation];
    self.session = nil;
}
#endif

#if AMZN_LOGIN
#pragma mark - Login With Amazon


- (void)AMZNLogin
{
    [AIMobileLib authorizeUserForScopes:[NSArray arrayWithObject:@"profile"] delegate:self];
}

- (void)AMZNLogout
{
    [AIMobileLib clearAuthorizationState:self];
}

- (void)requestDidSucceed:(APIResult*) apiResult {
    if (apiResult.api == kAPIAuthorizeUser) {
        [AIMobileLib getAccessTokenForScopes:[NSArray arrayWithObject:@"profile"] withOverrideParams:nil delegate:self];
    }
    else if (apiResult.api == kAPIGetAccessToken) {
        NSString *token = (NSString *)apiResult.result;
        NSLog(@"%@", token);
        
        self.provider = [[AmazonWIFCredentialsProvider alloc] initWithRole:AMZN_ROLE_ARN
                                              andWebIdentityToken:token
                                                     fromProvider:@"www.amazon.com"];
        
        // if we don't have an ID, we may need to initialize in offline mode
        if (self.provider.subjectFromWIF == nil) {
            [self attemptOfflineLogin];
        }
        // if we have an id, we are logged in
        else {
            NSLog(@"IDP id: %@", self.provider.subjectFromWIF);
            [AmazonKeyChainWrapper storeIdentityProvider:AMZN_PROVIDER andUserID:self.provider.subjectFromWIF];
            [self initClients];
        }
        
        if (self.callback) {
            self.callback(nil);
            self.callback = nil;
        }
    }
}

- (void)requestDidFail:(APIError*) errorResponse {
    [[AmazonClientManager errorAlert:[NSString stringWithFormat:@"Error logging in with Amazon: %@", errorResponse.error.message]] show];
    
    if (self.callback) {
        self.callback(nil);
        self.callback = nil;
    }
}

#endif

#if GOOGLE_LOGIN
#pragma mark - Google
- (GPPSignIn *)getGPlusLogin
{
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.delegate = self;
    signIn.clientID = GOOGLE_CLIENT_ID;
    signIn.scopes = [NSArray arrayWithObjects:GOOGLE_CLIENT_SCOPE, GOOGLE_OPENID_SCOPE, nil];
    return signIn;
}

- (void)GoogleLogin
{
    GPPSignIn *signIn = [self getGPlusLogin];
    [signIn authenticate];
}

- (void)GoogleLogout
{
    GPPSignIn *signIn = [self getGPlusLogin];
    [signIn disconnect];
    self.auth = nil;
}

- (void)reloadGSession
{
    GPPSignIn *signIn = [self getGPlusLogin];
    [signIn trySilentAuthentication];
}

- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error
{
    if (self.auth == nil) {
        self.auth = auth;
        
        if (error != nil) {
            [[AmazonClientManager errorAlert:[NSString stringWithFormat:@"Error logging in with Google: %@", error.description]] show];
        }
        else {
            [self CompleteGLogin];
        }
    }
}

-(void)CompleteGLogin
{
    NSString *idToken = [self.auth.parameters objectForKey:@"id_token"];
    
    self.provider = [[AmazonWIFCredentialsProvider alloc] initWithRole:GOOGLE_ROLE_ARN
                                          andWebIdentityToken:idToken
                                                 fromProvider:nil];
    
    // if we don't have an ID, we may need to initialize in offline mode
    if (self.provider.subjectFromWIF == nil) {
        [self attemptOfflineLogin];
    }
    // if we have an id, we are logged in
    else {
        NSLog(@"IDP id: %@", self.provider.subjectFromWIF);
        [AmazonKeyChainWrapper storeIdentityProvider:GOOGLE_PROVIDER andUserID:self.provider.subjectFromWIF];
        [self initClients];
    }
    
    if (self.callback) {
        self.callback(nil);
        self.callback = nil;
    }
}
#endif

@end
