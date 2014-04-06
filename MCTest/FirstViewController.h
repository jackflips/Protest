//
//  FirstViewController.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MapKit;

@interface FirstViewController : UIViewController <UITextFieldDelegate, MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtMessage;
@property (weak, nonatomic) IBOutlet UITextView *tvChat;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)sendMessage:(id)sender;
- (IBAction)cancelMessage:(id)sender;
- (void)appendMessage:(id)sender;
- (void)appendMessageFromLeader:(NSArray*)sender;


@end
