//
//  MCManager.m
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "MCManager.h"

@implementation MCManager

- (id)init{
    self = [super init];
    
    if (self) {
        _peerID = nil;
        _session = nil;
        _browser = nil;
        _advertiser = nil;
    }
    
    [self setupPeerAndSessionWithDisplayName:@"Jack's iPhone"];
    [self advertiseSelf];
    [self browse];
    
    return self;
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
    NSLog(@"started advertising");
}

- (void)browse {
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID serviceType:@"crowd"];
    [_browser setDelegate:self];
    [_browser startBrowsingForPeers];
    NSLog(@"started browsing");
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"didn't start browsing for peers");
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"found peer");
    [_browser invitePeer:peerID toSession:_session withContext:[NSData data] timeout:-1];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"browser lost peer");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser fucked up");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    NSLog(@"did recieve invitation from peer");
    MCSession *session = [[MCSession alloc] initWithPeer:peerID
                                        securityIdentity:nil
                                    encryptionPreference:MCEncryptionNone];
    session.delegate = self;
    
    invitationHandler(YES, session);
}


-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"peer did change state");
    NSLog(@"%d", state);
    if (state == MCSessionStateConnected) {
        NSLog(@"connected?");
        NSString *str = @"you are connected good job";
        NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        [_session sendData:data toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    }
}



-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSLog(@"session did receive data");
    NSString* newStr = [NSString stringWithUTF8String:[data bytes]];
    NSLog(@"%@", newStr);
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
