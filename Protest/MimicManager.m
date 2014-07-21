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
    [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:.4 target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:.8 target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
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
    [_connectionManager sendMessage:@[@"Mimic"] toPeer:_peer];
}

- (void)recievedMimic {
    float interval = [self randomFloatBetween:.1 and:.35];
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(sendMimicTraffic) userInfo:nil repeats:NO];
}

@end
