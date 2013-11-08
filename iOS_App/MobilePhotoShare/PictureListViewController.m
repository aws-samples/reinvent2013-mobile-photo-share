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

#import "PictureListViewController.h"
#import "Constants.h"
#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"
#import "PictureShowViewController.h"
#import "Favorites.h"
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import <AWSDynamoDB/AWSDynamoDB.h>

@implementation PictureName

@synthesize title;
@synthesize key;

@end


@interface PictureListViewController ()

@end

@implementation PictureListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[AmazonClientManager sharedInstance] isLoggedIn]) {
        [self getPicturesForType:@"Personal"];
        for (UITabBarItem *item in self.tabBar.items) {
            if ([item.title isEqualToString:@"Personal"]) {
                self.tabBar.selectedItem = item;
                break;
            }
        }
    }
    else {
        [self getPicturesForType:@"Public"];
        for (UITabBarItem *item in self.tabBar.items) {
            if ([item.title isEqualToString:@"Public"]) {
                self.tabBar.selectedItem = item;
            }
            else {
                item.enabled = NO;
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [pictures count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PictureCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell...
    PictureName *pictureName = [pictures objectAtIndex:indexPath.row];
    cell.textLabel.text = pictureName.title;
    cell.userInteractionEnabled = (pictureName.key != nil);
    
    return cell;
}

#pragma mark - UITableViewDelegate

// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// This will get called too before the view appears
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get destination view
    PictureShowViewController *showController = [segue destinationViewController];
    
    // Pass the information to your destination view
    PictureName *picture = [pictures objectAtIndex:self.tableView.indexPathForSelectedRow.row];
    showController.imageName = picture.key;
}

#pragma mark - IBActions

-(IBAction)dismissPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITabBarDelegate



- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self getPicturesForType:item.title];
}

#pragma mark -

- (void)getPicturesForType:(NSString *)type
{
    if ( [type isEqualToString:@"Favorites"] ) {
        [pictures removeAllObjects];
        [self getPictureNamesAndDisplay:[[Favorites getFavorites] allObjects]];
    }
    else if ( [type isEqualToString:@"Personal"] ) {
        [self getUserPictures:@"Personal"];
    }
    else if ( [type isEqualToString:@"Public"] ) {
        [self getUserPictures:@"Public"];
    }
}

-(void)getPictureNamesAndDisplay:(NSArray*)keys
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            self.tabBar.userInteractionEnabled = NO;
        });
        
        for (NSString *objectKey in keys) {
            PictureName *pn = [PictureName new];
            pn.title = [objectKey lastPathComponent];
            pn.key = objectKey;
            [pictures addObject:pn];
        }
        
        if ([pictures count] == 0) {
            PictureName *pn = [PictureName new];
            pn.title = @"No pictures for this type";
            [pictures addObject:pn];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [self.tableView reloadData];
            self.tabBar.userInteractionEnabled = YES;
        });
    });
    
}

- (void)getUserPictures:(NSString*)type
{
    prefix = nil;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            self.tabBar.userInteractionEnabled = NO;
        });
        
        if ([AmazonKeyChainWrapper userId] && [type isEqualToString:@"Personal"]) {
            prefix = [NSString stringWithFormat:@"%@/", [AmazonKeyChainWrapper userId]];
        }
        else {
            prefix = [NSString stringWithFormat:@"%@/", @"public"];
        }

        // get our data
        S3ListObjectsRequest *listRequest = [S3ListObjectsRequest new];
        listRequest.bucket = BUCKET_NAME;
        listRequest.prefix = prefix;
        
        S3ListObjectsResponse *listResponse = [[[AmazonClientManager sharedInstance] s3] listObjects:listRequest];
        if (listResponse.error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Error getting pictures: %@", listResponse.error.description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            });
        }
        
        if (pictures == nil) {
            pictures = [[NSMutableArray alloc] initWithCapacity:[listResponse.listObjectsResult.objectSummaries count]];
        }
        else {
            [pictures removeAllObjects];
        }
        [AmazonLogger turnLoggingOff];
        
        NSMutableArray *keys = [[NSMutableArray alloc] init];
        for (S3ObjectSummary *object in listResponse.listObjectsResult.objectSummaries) {
            // don't add the 0 byte "directory objects"
            if (![object.key hasSuffix:@"/"]) {
                [keys addObject:object.key];
            }
        }
        
        [self getPictureNamesAndDisplay:keys];
    });
}


@end
