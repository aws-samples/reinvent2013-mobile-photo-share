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

#import <UIKit/UIKit.h>
#import <AWSRuntime/AWSRuntime.h>
#import <CoreLocation/CoreLocation.h>

@interface AddPictureViewController : UIViewController<CLLocationManagerDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate,AmazonServiceRequestDelegate>

@property (nonatomic) IBOutlet UIImageView *previewImage;
@property (nonatomic) IBOutlet UISwitch *publicSwitch;
@property (nonatomic) IBOutlet UIButton *submitButton;
@property (nonatomic) NSData *imageData;
@property (nonatomic) IBOutlet UITextField *name;
@property (nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic, strong) CLLocationManager *locationManager;

-(IBAction)selectPicture:(id)sender;
-(IBAction)submitPicture:(id)sender;
-(IBAction)cancel:(id)sender;

@end
