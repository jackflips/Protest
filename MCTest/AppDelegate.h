//
//  AppDelegate.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    MCManager *manager;
}

@property (strong, nonatomic) UIWindow *window;

@end
