//
//  MCManager.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <CommonCrypto/CommonDigest.h>
#import "Peer.h"
#import "WJLPkcsContext.h"
#import "Message.h"
#import "ProtestViewController.h"


@interface ConnectionManager : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) NSMutableDictionary *sessions;
@property (nonatomic, assign) BOOL leader;
@property (nonatomic, strong) NSMutableArray *currentRequestingPeers;
@property (nonatomic, strong) NSMutableDictionary *allMessages;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *nameOfProtest;
@property (nonatomic, strong) NSMutableDictionary *foundProtests;

@property (nonatomic) SecKeyRef leadersPublicKey;

- (void)joinProtest:(NSString*)protestName password:(NSString*)password;
- (void)startProtest:(NSString*)name password:(NSString*)password;
- (void)sendMessage:(Message*)message;
- (void)pruneTree;
- (void)searchForProtests;
- (void)disconnectFromPeers;
- (void)testMessageSending;

@end
