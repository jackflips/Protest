//
//  AppDelegate.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "ChatViewController.h"
#import "ConnectionManager.h"

@class ProtestViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) SecKeyRef leaderKey;
@property (strong, nonatomic) ConnectionManager *manager;
@property (strong, nonatomic, retain) ChatViewController *chatViewController;
@property (strong, nonatomic, retain) ProtestViewController *viewController;
@property (strong, nonatomic) CryptoManager *cryptoManager;
@property (nonatomic) BOOL DIAGNOSTIC_MODE;

-(void)addMessageToChat:(Message*)message;

@end
