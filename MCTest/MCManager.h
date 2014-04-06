//
//  MCManager.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "AeroGearCrypto.h"

@interface MCManager : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) NSMutableArray *peers;
@property (nonatomic, strong) NSData *publicKey;
@property (nonatomic, assign) BOOL leader;

- (id)initWithPublicKey:(NSData *)publicKey;
- (void)connect;
- (void)setPublicKey:(NSData *)publicKey;
- (void)joinProtest;

@end
