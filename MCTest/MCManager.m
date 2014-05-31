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

@interface MCManager()

@property (nonatomic, retain) AppDelegate *appDelegate;

@end

@implementation MCManager

- (id)init{
    self = [super init];
    
    if (self) {
        _session = nil;
        _peerID = nil;
        _browser = nil;
        _advertiser = nil;
        _leadersPublicKey = nil;
        _leader = NO;
        _sessions = [[NSMutableDictionary alloc] init];
        _currentRequestingPeers = [[NSMutableArray alloc] init];
        _allMessages = [[NSMutableDictionary alloc] init];
        _userID = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] substringToIndex:8];
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _password = nil;
        _nameOfProtest = nil;
        
        _cryptoManager = [[WJLPkcsContext alloc] init];
    }
    return self;
}

- (void)testMessageSending {
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(sendamessage)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)sendamessage {
    Message *message = [[Message alloc] initWithMessage:@"In 2012, he was named by Time Magazine as one of the 100 most influential people in the world. He's crippled international fraud." uID:@"1234" fromLeader:YES];
    [_appDelegate addMessageToChat:message];
    Message *message1 = [[Message alloc] initWithMessage:@"Medical school." uID:@"1235" fromLeader:YES];
    [_appDelegate addMessageToChat:message1];
}

- (void)hashTest {
    NSString *test = @"test data";
    NSString *falseTest = @"test data";
    NSData *testData1 = [falseTest dataUsingEncoding:NSUTF8StringEncoding];
    NSData *testData = [test dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *sig = [_cryptoManager sign:testData withKey:_cryptoManager.privateKey];
    OSStatus status = [_cryptoManager verify:testData1 withSignature:sig andKey:_cryptoManager.publicKey];
    NSLog(@"%d", (int)status);
    
}

- (void)startProtest:(NSString*)name password:(NSString*)password {
    _nameOfProtest = name;
    _password = password;
    [self setupPeerAndSessionWithDisplayName:_userID];
    [self connect];
}

- (void)browseForProtests {
    [self setupPeerAndSessionWithDisplayName:_userID];
    [self advertiseSelf];
    
}

- (void)connectToPeer:(MCPeerID*)peer password:(NSString*)password {
    [_browser invitePeer:peer toSession:_session withContext:[password dataUsingEncoding:NSUTF8StringEncoding] timeout:30.0];
}

- (void)connect {
    [self setupPeerAndSessionWithDisplayName:_userID];
    [self browse];
}

- (void)joinProtest {
    [self setupPeerAndSessionWithDisplayName:_userID];
    //[self advertiseSelf];
}

- (void)setupPeerAndSessionWithDisplayName:(NSString *)displayName{
    _peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    _session = [[MCSession alloc] initWithPeer:_peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    _session.delegate = self;
}

- (void)advertiseSelf {
    NSDictionary *emptyDict = [[NSDictionary alloc] init];
    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID discoveryInfo:emptyDict serviceType:@"Protest"];
    [_advertiser setDelegate:self];
    [_advertiser startAdvertisingPeer];
}

- (void)browse {
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID serviceType:@"Protest"];
    [_browser setDelegate:self];
    [_browser startBrowsingForPeers];
}

- (NSData *)getPublicKeyBitsFromKey:(SecKeyRef)givenKey {
    
    static const uint8_t publicKeyIdentifier[] = "com.your.company.publickey";
    NSData *publicTag = [[NSData alloc] initWithBytes:publicKeyIdentifier length:sizeof(publicKeyIdentifier)];
    
    OSStatus sanityCheck = noErr;
    NSData * publicKeyBits = nil;
    
    NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Temporarily add key to the Keychain, return as data:
    NSMutableDictionary * attributes = [queryPublicKey mutableCopy];
    [attributes setObject:(__bridge id)givenKey forKey:(__bridge id)kSecValueRef];
    [attributes setObject:@YES forKey:(__bridge id)kSecReturnData];
    CFTypeRef result;
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) attributes, &result);
    if (sanityCheck == errSecSuccess) {
        publicKeyBits = CFBridgingRelease(result);
        
        // Remove from Keychain again:
        (void)SecItemDelete((__bridge CFDictionaryRef) queryPublicKey);
    }
    
    return publicKeyBits;
}


- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"didn't start browsing for peers");
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"found peer");
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //data schema: { nameOfProtest, boolPassword, myPublicKey }
    BOOL isPassword = NO;
    if (_password) isPassword = YES;
    NSArray *invitation = [NSArray arrayWithObjects:_nameOfProtest, isPassword, _cryptoManager.publicKey, nil];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:invitation];
    [browser invitePeer:peerID toSession:_session withContext:data timeout:120.0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"browser lost peer");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser fucked up");
}


- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    if (context) {
        NSLog(@"%@", context);
        invitationHandler(YES, self.session);
    }
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"%ld", state);
    if (state == MCSessionStateConnected) {
        NSError *error;
        NSArray *array = [[NSArray alloc] initWithObjects:@"Keyflag", _cryptoManager.publicKey, nil];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
        NSArray *allPeers = _session.connectedPeers;
        [_session sendData:data toPeers:[NSArray arrayWithObject:allPeers] withMode:MCSessionSendDataReliable error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

- (NSData*)encryptMessage:(NSData*)message andPublicKey:(SecKeyRef)publicKey {
    return [_cryptoManager encrypt:message WithPublicKey:publicKey];
}

- (NSData*)decryptMessage:(NSData*)message {
    return [_cryptoManager decrypt:message];
}

- (void)gossip {
    for (Graph *peer in _sessions) {
        NSArray *array = [[NSArray alloc] initWithObjects:@"GossipRequest", nil];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
        data = [self encryptMessage:data andPublicKey:peer.key];
        NSArray *allPeers = peer.session.connectedPeers;
        NSError *error;
        peer.requestOut = YES;
        [peer.session sendData:data toPeers:[NSArray arrayWithObject:allPeers] withMode:MCSessionSendDataReliable error:&error];
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

- (void)sendFirstOrderPeerTree:(Graph*)peer {
    NSError *error;
    NSArray *peerId = peer.session.connectedPeers; //remember, just one peer per session.
    for (Graph* graph in _sessions) {
        if ([graph getAgeSinceReset] < PRUNE) {
            NSArray *gossipResponse = [[NSArray alloc] initWithObjects:@"GossipResponse", _cryptoManager.publicKey, graph.key, nil];
            NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:gossipResponse];
            responseData = [_cryptoManager encrypt:responseData WithPublicKey:peer.key];
            [peer.session sendData:responseData toPeers:peerId withMode:MCSessionSendDataReliable error:&error];
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
    NSData *decryptedData = [_cryptoManager decrypt:messageData];
    NSArray *data = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
    Graph *thisPeer = [_sessions objectForKey:peerID];
    
    if ([[data objectAtIndex:0] isEqualToString:@"Keyflag"]) {
        Graph *newPeer = [[Graph alloc] initWithKey:(__bridge SecKeyRef)([data objectAtIndex:1]) andSession:_session];
        [_sessions setObject:newPeer forKey:peerID];
        _session = nil;
        [self gossip];
    }
    
    else if ([[data objectAtIndex:0] isEqualToString:@"GossipRequest"]) {
        if (![self needsToRefreshPeerList]) {
            [self sendFirstOrderPeerTree:thisPeer];
        } else {
            [self sendFirstOrderPeerTree:thisPeer]; //only sends young peers
            thisPeer.isParent = YES;
            [self gossip];
        }
    }
    
    else if ([[data objectAtIndex:0] isEqualToString:@"GossipResponse"]) {
        //check length of nsarray to see if it is multihop response or 1
        if ([data count] > 2) { //multihop repsponse
            for (Graph *peer in _sessions) {
                if ([(NSData*)peer.key isEqualToData:(NSData*)[data objectAtIndex:1]]) {
                    [peer.peers addObject:[[Graph alloc] initWithKey:(__bridge SecKeyRef)([data objectAtIndex:2])]];
                }
            }
        } else if ([data count] <= 2) { //first order response
            [thisPeer resetAge];
            thisPeer.requestOut = NO;
            //forward requests to parents. we clear the parent list if all peers have returned
            if ([self updateParents]) {
                for (Graph *peer in _sessions) {
                    if (peer.isParent) {
                        NSError *error;
                        NSArray *gossipResponse = [[NSArray alloc] initWithObjects:@"GossipResponse", _cryptoManager.publicKey, [data objectAtIndex:1], nil];
                        NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:gossipResponse];
                        responseData = [_cryptoManager encrypt:responseData WithPublicKey:peer.key];
                        [peer.session sendData:responseData toPeers:[[_sessions allKeysForObject:peer] objectAtIndex:0] withMode:MCSessionSendDataReliable error:&error];
                    }
                }
            }
        }
    }
    
    else if ([[data objectAtIndex:0] isEqualToString:@"Message"]) {
        /*
         Checks to see if you sent a message that hasn't been propogated back to you yet. If it's not your message, then adds it to the buffer.
         data representation: [@“”Message”, hash, userid, message, (signature)]
        */
        Message *thisMessage = [_allMessages objectForKey:[data objectAtIndex:1]];
        if (!thisMessage) {
            Message *newMessage = [[Message alloc] initWithMessage:[data objectAtIndex:3] uID:[data objectAtIndex:2] fromLeader:YES];
            if ([data count] >= 5) {
                OSStatus status = [_cryptoManager verify:[data objectAtIndex:3] withSignature:[data objectAtIndex:4] andKey:_cryptoManager.publicKey];
                if (status == 0) { //if verified...
                    newMessage.fromLeader = YES;
                }
            }
            [_allMessages setObject:newMessage forKey:[data objectAtIndex:1]];
            [_appDelegate addMessageToChat:thisMessage];
        }
        else if (thisMessage.timer) { //if you sent the message and it had a timer, delete it.
            [thisMessage.timer invalidate];
            thisMessage.timer = nil;
        }
        else if (thisMessage) {
            return;
        }
        [self forwardMessage:decryptedData];
    }
    
    else if ([[data objectAtIndex:0] isEqualToString:@"Forward"]) {
        for (MCPeerID *key in _sessions) {
            if ([key.displayName isEqualToString:[[data objectAtIndex:1] displayName]]) {
                NSError *error;
                [[[_sessions objectForKey:key] session] sendData:[data objectAtIndex:2] toPeers:[NSArray arrayWithObject:key] withMode:MCSessionSendDataReliable error:&error];
            }
        }
    }
}

- (void)forwardMessage:(NSData*)data {
    for (MCPeerID* key in _sessions) {
        Graph *peer = [_sessions objectForKey:key];
        data = [_cryptoManager encrypt:data WithPublicKey:peer.key];
        NSError *error;
        [peer.session sendData:data toPeers:[NSArray arrayWithObject:key] withMode:MCSessionSendDataReliable error:&error];
    }
}

- (void)messageExpired:(Message *)message {
    [self sendMessage:message.message];
    [_allMessages removeObjectForKey:message.hash];
}

- (NSString*)getTimeString {
    CFAbsoluteTime timeOfMessage = CFAbsoluteTimeGetCurrent();
    CFDateRef cfDate = CFDateCreate(kCFAllocatorDefault, timeOfMessage);
    CFDateFormatterRef dateFormatter = CFDateFormatterCreate(kCFAllocatorDefault, CFLocaleCopyCurrent(), kCFDateFormatterFullStyle, kCFDateFormatterFullStyle);
    return (__bridge NSString *)(CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, dateFormatter, cfDate));
}

- (NSString*)MD5:(NSString*)stringToHash {
    const char *ptr = [stringToHash UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    return output;
}

- (void)sendMessage:(NSString*)message {
    NSString *time = [self getTimeString];
    NSString *toHash = [NSString stringWithFormat: @"%@%@%@", time, _userID, message];
    NSString *hash = [self MD5:toHash];
    NSArray *messageToSend;
    if (_leader) {
        NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSData *sig = [_cryptoManager sign:messageData withKey:_cryptoManager.privateKey];
        [NSArray arrayWithObjects:@"Message", hash, _userID, message, sig, nil];
    } else {
        [NSArray arrayWithObjects:@"Message", hash, _userID, message, nil];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:messageToSend];
    NSMutableArray *candidates = [NSMutableArray array];
    for (MCPeerID *key in _sessions) {
        if ([[[_sessions objectForKey:key] peers] count] > 0) {
            [candidates addObject:[_sessions objectForKey:key]];
        }
    }
    Graph *firstHop = [candidates objectAtIndex:arc4random() % [candidates count]];
    Graph *secondHop = [firstHop.peers objectAtIndex:arc4random() % firstHop.peers.count];
    MCPeerID *secondHopPeerID = [secondHop.session.connectedPeers objectAtIndex:0];
    NSData *secondHopData = [_cryptoManager encrypt:data WithPublicKey:secondHop.key];
    //intermediate hop data is like [@"Forward", Public key to forward to, data]
    //we really should do 3 hops...
    NSArray *firstHopDataArray = [NSArray arrayWithObjects:@"Forward", secondHopPeerID, secondHopData, nil];
    NSData *firstHopData = [NSKeyedArchiver archivedDataWithRootObject:firstHopDataArray];
    firstHopData = [_cryptoManager encrypt:firstHopData WithPublicKey:firstHop.key];
    NSError *error;
    [firstHop.session sendData:firstHopData toPeers:firstHop.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
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
