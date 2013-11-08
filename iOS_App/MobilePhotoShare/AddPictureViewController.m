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

#import "Constants.h"
#import "GeoClient.h"
#import "Pictures.h"

#import "AddPictureViewController.h"
#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"

#import <AWSS3/AWSS3.h>

@interface AddPictureViewController ()

@end

@implementation AddPictureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.submitButton.enabled = NO;
    self.progressView.hidden = YES;
    self.progressView.progress = 0.0;
	// Do any additional setup after loading the view.
    
    // Start the location manager.
	[[self locationManager] startUpdatingLocation];
}

- (void)viewDidUnload {
	// Release any properties that are loaded in viewDidLoad or can be recreated lazily.
	self.locationManager = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

-(IBAction)selectPicture:(id)sender {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [self selectPictureFromCamera];
    }
    else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        [self selectPictureFromLibrary];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to select images" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

-(IBAction)submitPicture:(id)sender {
    [self.name resignFirstResponder];

    if ( [self.name.text length] < 1 ) {
        [[Constants noImageNameAlert] show];
    }
    else {
        self.progressView.hidden = NO;
        
        NSString *imageUrl = nil;
        if ( self.publicSwitch.isOn ) {
            imageUrl = [NSString stringWithFormat:@"public/%@/%@.jpg", [AmazonKeyChainWrapper userId], self.name.text];
        }
        else {
            imageUrl = [NSString stringWithFormat:@"%@/%@.jpg", [AmazonKeyChainWrapper userId], self.name.text];
        }
        
        // Upload picture 
        [Pictures uploadPicture:self.imageData key:imageUrl delegate:self];

        
        // Capture picture location.
        [GeoClient storeGeoPoint:/*[self.locationManager location]*/ [[CLLocation alloc] initWithLatitude:36.1208 longitude:-115.1722]
                          userId:[AmazonKeyChainWrapper userId]
                             url:imageUrl
                           title:self.name.text
                        delegate:nil];
    }
}

-(IBAction)cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Image Selection

-(void)selectPictureFromCamera
{
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentModalViewController:picker animated:YES];
}

-(void)selectPictureFromLibrary
{
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentModalViewController:picker animated:YES];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
         didFinishPickingImage:(UIImage *)image
                   editingInfo:(NSDictionary *)editingInfo
{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // Convert the image to JPEG data.
        self.imageData = UIImageJPEGRepresentation(image, 1.0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.previewImage.image = image;
            self.submitButton.enabled = YES;
        });
    });
    [picker dismissModalViewControllerAnimated:YES];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    self.progressView.hidden = YES;
    [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Upload Complete!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{    
    [self performSelectorOnMainThread:@selector(updateProgressView:) withObject:[NSNumber numberWithFloat:(float)totalBytesWritten / totalBytesExpectedToWrite] waitUntilDone:NO];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Error during upload" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark -
#pragma mark Location manager

/**
 * Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
    
    if (_locationManager != nil) {
		return _locationManager;
	}
    
	_locationManager = [[CLLocationManager alloc] init];
	[_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
	[_locationManager setDelegate:self];
    
	return _locationManager;
}

#pragma mark -
#pragma mark Text Field

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField:self.name up:YES];
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:self.name up:NO];
}

-(void)animateTextField:(UITextField *)textField up:(BOOL)moveUp
{
    int move = 120;
    
    if (moveUp) {
        move = -120;
    }
    
    [UIView beginAnimations:@"animation" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.25f];
    self.view.frame = CGRectOffset(self.view.frame, 0, move);
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark Helper Functions

-(void)updateProgressView:(NSNumber *)theProgress
{
    self.progressView.progress = [theProgress floatValue];
}

-(void)hideProgressView
{
    self.progressView.hidden = YES;
}

@end
