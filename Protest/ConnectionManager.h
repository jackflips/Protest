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
#import "CryptoManager.h"
#import "Message.h"
#import "ProtestViewController.h"


@interface ConnectionManager : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate> {
    enum ProtestNetworkState : NSUInteger {
        ProtestNetworkStateNotConnected,
        ProtestNetworkStateConnected,
    };
    BOOL censusOut;
    int networkSize;
    NSString *DIAGNOSTIC_ADDRESS;
}

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCSession *anotherSession;
@property (nonatomic, strong) NSMutableDictionary *sessions;
@property (nonatomic, assign) BOOL leader;
@property (nonatomic, assign) BOOL currentlyBrowsing;
@property (nonatomic, strong) NSMutableArray *currentRequestingPeers;
@property (nonatomic, strong) NSMutableDictionary *allMessages;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *nameOfProtest;
@property (nonatomic, strong) NSMutableDictionary *foundProtests;
@property (nonatomic, strong) NSMutableArray *secretMessagePath;
@property (nonatomic) enum ProtestNetworkState state;

@property (nonatomic) SecKeyRef leadersPublicKey;

- (void)joinProtest:(NSString*)protestName password:(NSString*)password;
- (void)startProtest:(NSString*)name password:(NSString*)password;
- (void)sendMessage:(id)message toPeer:(Peer*)peer;
- (void)sendMessage:(Message*)message;
- (void)pruneTree;
- (void)searchForProtests;
- (void)disconnectFromPeers;
- (void)testMessageSending;

@end
