//
//  Message.m
//  MCTest
//
//  Created by John Rogers on 5/2/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "Message.h"

@implementation Message

- (id)initWithMessage:(NSString*)message uID:(NSString*)uID fromLeader:(BOOL)fromLeader{
    self = [super init];
    _message = message;
    _uId = uID;
    _md5hash = nil;
    _fromLeader = fromLeader;
    return self;
}

- (void)startTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(messageExpired)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)messageExpired {
}


@end
