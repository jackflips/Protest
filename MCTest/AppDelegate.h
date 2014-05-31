//
//  AppDelegate.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "FirstViewController.h"
#import "MCManager.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) SecKeyRef leaderKey;
@property (strong, nonatomic) MCManager *manager;
@property (strong, nonatomic) FirstViewController *firstViewController;
@property (strong, nonatomic) ViewController *viewController;

-(void)addMessageToChat:(Message*)message;

@end
