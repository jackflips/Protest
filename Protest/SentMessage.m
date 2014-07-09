//
//  SentMessage.m
//  MCTest
//
//  Created by John Rogers on 5/2/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "Message.h"

@implementation SentMessage

- (id)initWithData:(NSString*)uID timeSent:(CFAbsoluteTime)timeSent message:(NSString*)message {
    self = [super init];
    [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(notifyManager:)
                                   userInfo:nil
                                    repeats:NO];
    return self;
}

- (void)notifyManager {
    AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [_appDelegate.manager messageExpired:self];
}

- (BOOL)checkForMatch:(SentMessage*)otherMessage {
    if ([otherMessage.id isEqualToString:_id] && otherMessage.timeSent == _timeSent && [otherMessage.message isEqualToString:_message]) {
        return YES;
    }
    return NO;
}

@end
