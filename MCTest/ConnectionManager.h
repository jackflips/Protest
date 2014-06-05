//
//  MCManager.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "Peer.h"
#import "WJLPkcsContext.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "Message.h"
#import "ProtestViewController.h"


@interface ConnectionManager : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCSession *advertisingSession;
@property (nonatomic, strong) MCSession *browsingSession;
@property (nonatomic, strong) NSMutableDictionary *sessions;
@property (nonatomic, assign) BOOL leader;
@property (nonatomic, strong) NSMutableArray *currentRequestingPeers;
@property (nonatomic, strong) WJLPkcsContext *cryptoManager;
@property (nonatomic, strong) NSMutableDictionary *allMessages;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSData *leadersPublicKey;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *nameOfProtest;
@property (nonatomic, strong) NSMutableDictionary *foundProtests;
@property (nonatomic, strong) NSMutableDictionary *quarantinedProtests;

- (void)joinProtest:(NSString*)protestName password:(NSString*)password;
- (void)startProtest:(NSString*)name password:(NSString*)password;
- (void)pruneTree;
- (void)sendMessage:(NSString*)message;
- (void)searchForProtests;
//- (void)connectToPeer:(MCPeerID*)peer password:(NSString*)password;
- (void)testMessageSending;

@end
