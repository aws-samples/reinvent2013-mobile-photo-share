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

#import "PictureMapViewController.h"
#import "PicturePointAnnotation.h"
#import "PictureShowViewController.h"

#import "Constants.h"
#import <AWSRuntime/AWSRuntime.h>
#import "AmazonClientManager.h"
#import "AmazonKeyChainWrapper.h"
#import "GeoClient.h"

@interface PictureMapViewController ()

@end

@implementation PictureMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(36.1208, -115.1722), MKCoordinateSpanMake(0.05, 0.05));
    self.mapView.delegate = self;
    [self queryArea];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Main methods

- (void)queryArea {
    self.data = [NSMutableData data];
    [GeoClient query:self.mapView.region.center.latitude
           longitude:self.mapView.region.center.longitude
              userId:[AmazonKeyChainWrapper userId]
              radius:5000
            delegate:self];
}

#pragma mark - MKMapViewDelegate methods

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self queryArea];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"Location"];
    if(!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Location"];
        
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
    }
    else {
        annotationView.annotation = annotation;
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"Show" sender:(PicturePointAnnotation *)view.annotation];
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSDictionary *resultDictionary = [NSJSONSerialization JSONObjectWithData:self.data
                                                                     options:kNilOptions
                                                                       error:nil];
    NSLog(@"Response:\n%@", resultDictionary);
    NSString *action = [resultDictionary objectForKey:@"action"];
    if([action isEqualToString:@"query"]) {
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        for (NSDictionary *jsonDic in [resultDictionary objectForKey:@"result"]) {
            PicturePointAnnotation *annotation = [PicturePointAnnotation new];
            annotation.coordinate = CLLocationCoordinate2DMake([[jsonDic objectForKey:@"latitude"] doubleValue],
                                                               [[jsonDic objectForKey:@"longitude"] doubleValue]);
            annotation.title = [jsonDic objectForKey:@"title"];
            annotation.imageUrl = [jsonDic objectForKey:@"rangeKey"];
            [self.mapView addAnnotation:annotation];
        }
    }
}

#pragma mark - IBActions

-(IBAction)dismissPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PicturePointAnnotation *annotation = (PicturePointAnnotation*)sender;
    
    PictureShowViewController *showController = [segue destinationViewController];
    showController.imageName = annotation.imageUrl;
    
    [self.navigationController pushViewController:showController animated:YES];
}

@end
