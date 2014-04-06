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


@implementation MCManager

- (id)init{
    self = [super init];
    
    if (self) {
        _peerID = nil;
        _session = nil;
        _browser = nil;
        _advertiser = nil;
        _publicKey = nil;
        _leader = NO;
    }
    return self;
}

- (id)initWithPublicKey:(NSData *)publicKey{
    self = [super init];
    
    if (self) {
        _peerID = nil;
        _session = nil;
        _browser = nil;
        _advertiser = nil;
        _publicKey = publicKey;
        _leader = NO;
    }
    return self;
}

- (void)setPublicKey:(NSData *)publicKey {
    _publicKey = publicKey;
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
    
    _session = [[MCSession alloc] initWithPeer:_peerID];
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
    [browser invitePeer:peerID toSession:self.session withContext:_publicKey timeout:30.0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"browser lost peer");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser fucked up");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    _publicKey = context;
    invitationHandler(YES, self.session);
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"peer did change state");
    NSLog(@"%ld", state);
}



-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    AppDelegate *_appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([[array objectAtIndex:0] isEqualToData:_publicKey]) { //if sender's public key matches ours... else do nothing.
        AGVerifyKey *verifyKey = [[AGVerifyKey alloc] initWithKey:_publicKey];
        BOOL isValid = NO;
        NSLog(@"array count: %lu", (unsigned long)[array count]);
        if ([array count] > 2) {
            isValid = [verifyKey verify:[array objectAtIndex:1] signature:[array objectAtIndex:2]];
        }
        NSLog(@"%d", isValid);
        if (isValid) {
            [_appDelegate.firstViewController appendMessage:[NSArray arrayWithObjects:[array objectAtIndex:1], peerID, nil]]; //from leader
        } else {
            [_appDelegate.firstViewController appendMessage:[NSArray arrayWithObjects:[array objectAtIndex:1], peerID, nil]]; //reg message
        }
    }
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
