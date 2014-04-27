//
//  MCManager.m
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "MCManager.h"
#import "FirstViewController.h"
#import "AppDelegate.h"

static const double PRUNE = 30.0;

@implementation MCManager

- (id)init{
    self = [super init];
    
    if (self) {
        _session = nil;
        _peerID = nil;
        _browser = nil;
        _advertiser = nil;
        _leader = NO;
        _sessions = [[NSMutableDictionary alloc] init];
        _currentRequestingPeers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSData*)encryptMessage:(NSData*)message {
    return message;
}

- (void)gossip {
    for (Graph *peer in _sessions) {
        NSArray *array = [[NSArray alloc] initWithObjects:@"GossipRequest", nil];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
        NSArray *allPeers = peer.session.connectedPeers;
        NSError *error;
        //need to encrypt as intermediate step here. need graph representation of this session for that.
        peer.requestOut = YES;
        [peer.session sendData:data toPeers:[NSArray arrayWithObject:allPeers] withMode:MCSessionSendDataReliable error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

- (void)reconnect {
    _session = nil;
    [self connect];
}

- (void)connect {
    [self setupPeerAndSessionWithDisplayName:@"iPhone"];
    [self advertiseSelf];
    [self browse];
}

- (void)joinProtest {
    [self setupPeerAndSessionWithDisplayName:@"protester"];
    [self advertiseSelf];
}

- (void)setupPeerAndSessionWithDisplayName:(NSString *)displayName{
    _peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    _session = [[MCSession alloc] initWithPeer:_peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    _session.delegate = self;
}

- (void)advertiseSelf {
    NSDictionary *emptyDict = [[NSDictionary alloc] init];
    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID discoveryInfo:emptyDict serviceType:@"crowd"];
    [_advertiser setDelegate:self];
    [_advertiser startAdvertisingPeer];
}

- (void)browse {
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID serviceType:@"crowd"];
    [_browser setDelegate:self];
    [_browser startBrowsingForPeers];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"didn't start browsing for peers");
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"found peer");
    AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [browser invitePeer:peerID toSession:_session withContext:_appDelegate.leaderKey timeout:30.0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"browser lost peer");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser fucked up");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.leaderKey = context;
    invitationHandler(YES, self.session);
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"%ld", state);
    if (state == MCSessionStateConnected) {
        AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSError *error;
        NSArray *array = [[NSArray alloc] initWithObjects:@"Keyflag", _appDelegate.myKey.publicKey, nil];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
        [_session sendData:data toPeers:[NSArray arrayWithObject:_session] withMode:MCSessionSendDataReliable error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}


- (void)pruneTree {
    for (Graph __strong *peer in _sessions) {
        if ([peer getAgeSinceReset] > PRUNE) {
            peer = nil;
        }
    }
}

- (BOOL)needsToRefreshPeerList {
    for (Graph *session in _sessions) {
        if ([session getAgeSinceReset] > PRUNE) {
            return YES;
        }
    }
    return NO;
}

- (void)sendFirstOrderPeerTree:(MCSession*)sessionToSendTo {
    NSError *error;
    NSArray *peer = sessionToSendTo.connectedPeers; //remember, just one peer per session.
    for (Graph* graph in _sessions) {
        if ([graph getAgeSinceReset] < PRUNE) {
            AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSArray *gossipResponse = [[NSArray alloc] initWithObjects:@"GossipResponse", _appDelegate.myKey.publicKey, graph.key, nil];
            NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:gossipResponse];
            [sessionToSendTo sendData:responseData toPeers:peer withMode:MCSessionSendDataReliable error:&error];
        }
    }
}

- (BOOL)updateParents {
    for (Graph *peer in _sessions) {
        if (peer.requestOut) {
            return YES;
        }
    }
    for (Graph *peer in _sessions) {
        peer.isParent = NO;
    }
    return NO;
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)messageData fromPeer:(MCPeerID *)peerID{
    AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *data = [NSKeyedUnarchiver unarchiveObjectWithData:messageData];
    
    if ([[data objectAtIndex:0] isEqualToString:@"Keyflag"]) {
        Graph *newPeer = [[Graph alloc] initWithKey:[data objectAtIndex:1] andSession:_session];
        [_sessions setObject:newPeer forKey:peerID];
        _session = nil;
        [self gossip];
    }
    
    else if ([[data objectAtIndex:0] isEqualToString:@"GossipRequest"]) {
        if (![self needsToRefreshPeerList]) {
            [self sendFirstOrderPeerTree:session];
        } else {
            [self sendFirstOrderPeerTree:session]; //only sends young peers
            Graph *thisPeer = [_sessions objectForKey:peerID];
            thisPeer.isParent = YES;
            [self gossip];
        }
    }
    
    else if ([[data objectAtIndex:0] isEqualToString:@"GossipResponse"]) {
        //check length of nsarray to see if it is multihop response or 1
        if ([data count] > 2) { //multihop repsponse
            for (Graph *peer in _sessions) {
                if ([peer.key isEqualToData:[data objectAtIndex:1]]) {
                    [peer.peers addObject:[[Graph alloc] initWithKey:[data objectAtIndex:2]]];
                }
            }
        } else if ([data count] <= 2) { //first order response
            Graph *peer = [_sessions objectForKey:peerID];
            [peer resetAge];
            peer.requestOut = NO;
            //forward requests to parents. we clear the parent list if all peers have returned
            if ([self updateParents]) {
                for (Graph *peer in _sessions) {
                    if (peer.isParent) {
                        NSError *error;
                        NSArray *gossipResponse = [[NSArray alloc] initWithObjects:@"GossipResponse", _appDelegate.myKey.publicKey, [data objectAtIndex:1], nil];
                        NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:gossipResponse];
                        [peer.session sendData:responseData toPeers:[[_sessions allKeysForObject:peer] objectAtIndex:0] withMode:MCSessionSendDataReliable error:&error];
                    }
                }
            }
        }
    }
    
    else if ([[data objectAtIndex:0] isEqualToString:@"Message"]) {
        if ([[data objectAtIndex:1] isEqualToData:_appDelegate.leaderKey]) { //if sender's public key matches ours...
            AGVerifyKey *verifyKey = [[AGVerifyKey alloc] initWithKey:_appDelegate.leaderKey];
            BOOL isValid = NO;
            NSLog(@"array count: %lu", (unsigned long)[data count]);
            if ([data count] > 2) {
                isValid = [verifyKey verify:[data objectAtIndex:2] signature:[data objectAtIndex:3]];
            }
            NSLog(@"%d", isValid);
            if (isValid) {
                [_appDelegate.firstViewController appendMessageFromLeader:[NSArray arrayWithObjects:[data objectAtIndex:2], peerID, nil]]; //from leader
            } else {
                [_appDelegate.firstViewController appendMessage:[NSArray arrayWithObjects:[data objectAtIndex:2], peerID, nil]]; //reg message
            }
        }
    }
}

- (void)sendMessage:(NSString*)message {
    
}


-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    NSLog(@"session did recieve resource");
}


-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    NSLog(@"session did finish recieving resource");
}


-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    NSLog(@"session did recieve stream");
}

@end
