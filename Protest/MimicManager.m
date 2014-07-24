//
//  MimicManager.m
//  Protest
//
//  Created by jack on 7/18/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "MimicManager.h"
#import "ConnectionManager.h"
#import "Peer.h"

@interface MimicManager()

@property (nonatomic, strong) ConnectionManager *connectionManager;
@property (nonatomic, strong) Peer *peer;

@end

@implementation MimicManager

- (id)initAndSendMimicWithConnectionManager:(ConnectionManager*)manager andPeer:(Peer*)peer {
    self = [super init];
    _connectionManager = manager;
    _peer = peer;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (int i=0; i<6; i++) {
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(.1 * (i+1)) target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
            [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        }
    }];
    return self;
}

- (id)initWithConnectionManager:(ConnectionManager*)manager andPeer:(Peer*)peer {
    self = [super init];
    _connectionManager = manager;
    _peer = peer;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
        [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    }];
    return self;
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)sendMimicTraffic {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [_connectionManager sendMessage:@[@"Mimic"] toPeer:_peer];
    }];
}

- (void)recievedMimic {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        float interval = [self randomFloatBetween:.1 and:.35];
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    }];
}

@end
