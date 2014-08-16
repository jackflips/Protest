//
//  Message.h
//  MCTest
//
//  Created by John Rogers on 5/2/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AppDelegate;

@interface Message : NSObject

//only messages that I send have timers (for verifying receipt)

@property (nonatomic, strong) NSString *uId;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic)         BOOL fromLeader;

- (id)initWithMessage:(NSString*)message uID:(NSString*)uID fromLeader:(BOOL)fromLeader;

@end
