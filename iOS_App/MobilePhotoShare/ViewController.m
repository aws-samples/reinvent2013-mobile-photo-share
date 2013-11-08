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

#import "ViewController.h"
#import "AmazonClientManager.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize loginButton=_loginButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[AmazonClientManager sharedInstance] resumeSessionWithCompletionHandler:^(NSError *error) {
        [self refreshUI];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refreshUI];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Helpers

-(void)refreshUI
{
    BOOL loggedIn = [[AmazonClientManager sharedInstance] isLoggedIn];
    BOOL authenticated = [[AmazonClientManager sharedInstance] isAuthenticated];
    if (loggedIn) {
        [self.loginButton setTitle:@"Logout"];
    }
    else {
        [self.loginButton setTitle:@"Login"];
    }
    self.addPictureButton.hidden = !loggedIn;
    self.showPicturesButton.hidden = !authenticated;
    self.pictureMapButton.hidden = !authenticated;
    self.notificationsButton.hidden = (!loggedIn || ![SNS_PLATFORM_APPLICATION_ARN hasPrefix:@"arn"]);
}

#pragma mark - IBActions

-(IBAction)loginButtonSelected:(id)sender
{
    if ([[AmazonClientManager sharedInstance] isLoggedIn]) {
        [[AmazonClientManager sharedInstance] logoutWithCompletionHandler:^(NSError *error) {
            [self refreshUI];
        }];
    }
    else {
        [[AmazonClientManager sharedInstance] loginFromView:self.view withCompletionHandler:^(NSError *error) {
            [self refreshUI];
        }];
    }
}

-(IBAction)receiveNotifications:(id)sender
{
    NSLog( @"Register for notifications" );
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];    
}

@end
