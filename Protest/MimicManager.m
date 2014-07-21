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
        NSTimer *timer1 = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
        [runLoop addTimer:timer1 forMode:NSDefaultRunLoopMode];
        NSTimer *timer2 = [NSTimer scheduledTimerWithTimeInterval:.4 target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
        [runLoop addTimer:timer2 forMode:NSDefaultRunLoopMode];
        NSTimer *timer3 = [NSTimer scheduledTimerWithTimeInterval:.8 target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
        [runLoop addTimer:timer3 forMode:NSDefaultRunLoopMode];
    }];
    return self;
}

- (id)initWithConnectionManager:(ConnectionManager*)manager andPeer:(Peer*)peer {
    self = [super init];
    _connectionManager = manager;
    _peer = peer;
    return self;
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)sendMimicTraffic {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSLog(@"sending mimic");
        [_connectionManager sendMessage:@[@"Mimic"] toPeer:_peer];
    }];
}

- (void)recievedMimic {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        float interval = [self randomFloatBetween:.1 and:.35];
        NSTimer *timer1 = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:timer1 forMode:NSDefaultRunLoopMode];
    }];
}

@end
