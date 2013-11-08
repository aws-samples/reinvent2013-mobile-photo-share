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

#import <AWSRuntime/AWSRuntime.h>
#import <AWSDynamoDB/AWSDynamoDB.h>
#import <AWSS3/AWSS3.h>
#import "PictureShowViewController.h"
#import "Constants.h"
#import "AmazonClientManager.h"
#import "Favorites.h"
#import "Pictures.h"

@interface PictureShowViewController ()
@property (nonatomic) NSString *filePath;
@end

@implementation PictureShowViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.imageName];
    NSFileManager *fm = [NSFileManager defaultManager];
   
    if ([fm fileExistsAtPath:self.filePath isDirectory:NO]){
        [fm removeItemAtPath:self.filePath error:nil];
    }
    else {
        //otherwise create directory structure, and initialize buffer
        NSString * directory = [self.filePath substringToIndex:
                                [self.filePath length] - [[self.filePath lastPathComponent] length]];
        [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    self.dataReceived = [NSMutableData new];
    
    // get the image data
    [Pictures downloadPicture:self.filePath key:self.imageName delegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.favButton.hidden = ![[AmazonClientManager sharedInstance] isLoggedIn];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateUI
{
    self.imageView.image = self.imageData;
}

#pragma mark - IBActions

-(IBAction)dismissPressed:(id)sender
{
    [[[AmazonClientManager sharedInstance] transferManager] cancelAllTransfers];
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)favPressed:(id)sender
{
    [[[AmazonClientManager sharedInstance] transferManager] cancelAllTransfers];
    
    [Favorites addFavorite:self.imageName];
}

-(IBAction)pausePressed:(id)sender
{
    UIButton *button = (UIButton*)sender;
    if ( [button.titleLabel.text isEqualToString:@"Pause"] ) {
        [[[AmazonClientManager sharedInstance] transferManager] pauseAllTransfers];
        [button setTitle:@"Resume" forState:UIControlStateNormal];
    }
    else {
        [[[AmazonClientManager sharedInstance] transferManager] resumeAllTransfers:self];
        [button setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

#pragma mark - AmazonServiceRequestDelegate Implementations

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
    [self.dataReceived appendData:data];
    self.imageData = [[UIImage alloc] initWithData:self.dataReceived];
    [self updateUI];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSLog( @"didFailWithError %@", error );
}


@end
