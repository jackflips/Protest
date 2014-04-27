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
#import "Graph.h"


@interface MCManager : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) NSMutableDictionary *sessions;
@property (nonatomic, strong) MCSession *searchingSession;
@property (nonatomic, assign) BOOL leader;
@property (nonatomic, strong) NSMutableArray *currentRequestingPeers;

- (void)connect;
- (void)joinProtest;
- (void)pruneTree;
- (void)sendMessage:(NSString*)message;

@end
