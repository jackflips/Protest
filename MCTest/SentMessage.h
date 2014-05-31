//
//  SentMessage.h
//  MCTest
//
//  Created by John Rogers on 5/2/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface SentMessage : NSObject

@property (nonatomic, strong) NSTimer *age;
@property (nonatomic, strong) NSString *id;
@property (nonatomic) CFAbsoluteTime timeSent;
@property (nonatomic, strong) NSString *message;

@end
