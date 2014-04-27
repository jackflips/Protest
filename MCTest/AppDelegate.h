//
//  AppDelegate.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCManager.h"
#import "AeroGearCrypto.h"
#import "FirstViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSData *leaderKey;
@property (strong, nonatomic) AGSigningKey *myKey;
@property (strong, nonatomic) MCManager *manager;
@property (strong, nonatomic) FirstViewController *firstViewController;

@end
