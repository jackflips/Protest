//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ConnectionManager.h"
#import "ChatViewController.h"
#import "AppDelegate.h"

static const double PRUNE = 30.0;

@interface ConnectionManager()

@property (nonatomic, retain) AppDelegate *appDelegate;

@end

@interface FoundProtest : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, copy) void (^joinProtest)(BOOL accept, MCSession *session);
@property (nonatomic, copy) MCPeerID *peer;
@property (nonatomic) SecKeyRef key;
@property (nonatomic) SecKeyRef leadersKey;

@end

@implementation FoundProtest
@end

@implementation ConnectionManager

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
        _allMessages = [[NSMutableDictionary alloc] init];
        _userID = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] substringToIndex:8];
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _password = nil;
        _nameOfProtest = nil;
        _foundProtests = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)disconnectFromPeers {
    for (id key in _sessions) {
        Peer *peer = [_sessions objectForKey:key];
        [peer.session disconnect];
    }
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
    NSString *falseTest = @"test dat12";
    NSData *testData1 = [falseTest dataUsingEncoding:NSUTF8StringEncoding];
    NSData *testData = [test dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *key = [self getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey];
    NSData *signedData = [_appDelegate.cryptoManager sign:testData withKey:_appDelegate.cryptoManager.privateKey];
    OSStatus *status = [_appDelegate.cryptoManager verify:testData withSignature:signedData andKey:_appDelegate.cryptoManager.publicKey];
    NSLog(@"%i", status);
    
}

- (void)startProtest:(NSString*)name password:(NSString*)password {
    _nameOfProtest = name;
    _password = password;
    _leadersPublicKey = _appDelegate.cryptoManager.publicKey;
    [_advertiser stopAdvertisingPeer];
    [_browser stopBrowsingForPeers];
    [self setupPeerAndSessionWithDisplayName:_userID];
    [self browse];
    //[self advertiseSelf];
}

- (void)browse {
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID serviceType:@"Protest"];
    [_browser setDelegate:self];
    [_browser startBrowsingForPeers];
}

- (void)searchForProtests {
    NSLog(@"advertising self 4 protests");
    [self setupPeerAndSessionWithDisplayName:_userID];
    [self advertiseSelf];
}

- (void)advertiseSelf {
    [_foundProtests removeAllObjects];
    if (_advertiser) {
        [_advertiser stopAdvertisingPeer];
    } else {
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID discoveryInfo:nil serviceType:@"Protest"];
    }
    [_advertiser setDelegate:self];
    [_advertiser startAdvertisingPeer];
}

- (void)joinProtest:(NSString*)protestName password:(NSString*)password {
    [_advertiser stopAdvertisingPeer];
    FoundProtest *prot = [_foundProtests objectForKey:protestName];
    Peer *newPeer = [[Peer alloc] initWithSession:_session];
    _nameOfProtest = prot.name;
    newPeer.key = prot.key;
    newPeer.isClient = YES;
    newPeer.peerID = prot.peer;
    [_sessions setObject:newPeer forKey:prot.peer.displayName];
    _password = password;
    _leadersPublicKey = prot.leadersKey;
    prot.joinProtest(YES, newPeer.session);
    _session = [[MCSession alloc] initWithPeer:_peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
}

- (void)setupPeerAndSessionWithDisplayName:(NSString *)displayName{
    _peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    _session = [[MCSession alloc] initWithPeer:_peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    _session.delegate = self;
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
    if (![_peerID.displayName isEqualToString:peerID.displayName] && ![_sessions objectForKey:peerID.displayName]) { //if we're not already connected to the peer
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        Peer *newPeer = [[Peer alloc] initWithSession:_session];
        newPeer.peerID = peerID;
        [_foundProtests setObject:newPeer forKey:peerID.displayName];
        NSArray *publicKeyArray = @[[self getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey]];
        NSData *publicKeyContext = [NSKeyedArchiver archivedDataWithRootObject:publicKeyArray];
        [browser invitePeer:peerID toSession:newPeer.session withContext:publicKeyContext timeout:120.0];
        _session = [[MCSession alloc] initWithPeer:_peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"browser lost peer");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser fucked up");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    Peer *newPeer = [[Peer alloc] initWithSession:_session];
    newPeer.isClient = YES;
    newPeer.peerID = peerID;
    newPeer.key = [_appDelegate.cryptoManager addPublicKey:[[NSKeyedUnarchiver unarchiveObjectWithData:context] objectAtIndex:0] withTag:peerID.displayName];
    [_foundProtests setObject:newPeer forKey:peerID.displayName];
    invitationHandler(YES, newPeer.session);
    _session = [[MCSession alloc] initWithPeer:_peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"did change state: %ld", state);
    if (state == MCSessionStateConnected) {
        NSLog(@"connected");
        Peer *peer = [_foundProtests objectForKey:peerID.displayName];
        if (peer.isClient) {
            NSError *error;
            NSArray *message = @[@"Handshake", [self getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey]];
            NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
            NSData *encryptedMessage = [_appDelegate.cryptoManager encrypt:messageData WithPublicKey:peer.key];
            [peer.session sendData:encryptedMessage toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error];
        }
    }
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler {
    certificateHandler(YES);
}


- (NSData*)encryptMessage:(NSData*)message andPublicKey:(SecKeyRef)publicKey {
    return [_appDelegate.cryptoManager encrypt:message WithPublicKey:publicKey];
}

- (NSData*)decryptMessage:(NSData*)message {
    return [_appDelegate.cryptoManager decrypt:message];
}

- (void)gossip {
    for (Peer *peer in _sessions) {
        NSArray *array = @[@"GossipRequest"];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
        data = [self encryptMessage:data andPublicKey:peer.key];
        NSError *error;
        peer.requestOut = YES;
        [peer.session sendData:data toPeers:@[peer.peerID] withMode:MCSessionSendDataReliable error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

- (void)pruneTree {
    for (Peer __strong *peer in _sessions) {
        if ([peer getAgeSinceReset] > PRUNE) {
            peer = nil;
        }
    }
}

- (BOOL)needsToRefreshPeerList {
    for (Peer *peer in [_sessions allValues]) {
        if ([peer getAgeSinceReset] > PRUNE) {
            return YES;
        }
    }
    return NO;
}

- (void)sendFirstOrderPeerTree:(Peer*)peer {
    NSError *error;
    for (Peer *newPeer in [_sessions allValues]) {
        if ([peer getAgeSinceReset] < PRUNE && newPeer != peer) {
            NSArray *gossip = [[NSArray alloc] initWithObjects:@"Gossip", [self getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey], newPeer.key, nil];
            NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:gossip];
            responseData = [_appDelegate.cryptoManager encrypt:responseData WithPublicKey:peer.key];
            [peer.session sendData:responseData toPeers:@[peer.peerID] withMode:MCSessionSendDataReliable error:&error];
        }
    }
}

- (BOOL)updateParents {
    for (Peer *peer in _sessions) {
        if (peer.requestOut) {
            return YES;
        }
    }
    for (Peer *peer in _sessions) {
        peer.isParent = NO;
    }
    return NO;
}

- (void)sendMessage:(NSArray*)message toPeer:(Peer*)peer {
    SecKeyRef key = peer.key;
    NSError *error;
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    NSData *encryptedMessage = [_appDelegate.cryptoManager encrypt:messageData WithPublicKey:key];
    [peer.session sendData:encryptedMessage toPeers:@[peer.peerID] withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)messageData fromPeer:(MCPeerID *)peerID{
    NSLog(@"recieved message");
    NSData *decryptedData = [_appDelegate.cryptoManager decrypt:messageData];
    NSArray *data = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
    NSLog(@"%@", data);
    Peer *thisPeer = [_sessions objectForKey:peerID.displayName];
    if (thisPeer == nil) thisPeer = [_foundProtests objectForKey:peerID.displayName];
    
    if ([[data objectAtIndex:0] isEqualToString:@"Handshake"]) {
        thisPeer.key = [_appDelegate.cryptoManager addPublicKey:[data objectAtIndex:1] withTag:peerID.displayName];
        BOOL isPassword = NO;
        if (_password) isPassword = YES;
        NSData *leadersKeyData = [self getPublicKeyBitsFromKey:_leadersPublicKey];
        NSArray *handshake2 = @[@"HandshakeBack", _nameOfProtest, [NSNumber numberWithBool:isPassword], leadersKeyData];
        [self sendMessage:handshake2 toPeer:thisPeer];
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"HandshakeBack"]) {
        if (_nameOfProtest
            && [[data objectAtIndex:1] isEqualToString:_nameOfProtest]
            && [_appDelegate.cryptoManager addPublicKey:[data objectAtIndex:3] withTag:peerID.displayName] == _leadersPublicKey) {
            
            //add connection
        } else {
            [_appDelegate.viewController addProtestToList:[data objectAtIndex:1] password:[[data objectAtIndex:2] boolValue] health:1];
        }
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"Ack"]) {
        NSLog(@"Succesfully connected to peer!");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_appDelegate.chatViewController chatLoaded:_nameOfProtest];
        }];
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"WrongPassword"]) {
        NSLog(@"entered wrong pw for peer");
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
    
    else if ([[data objectAtIndex:0] isEqualToString:@"Gossip"]) {
        //check length of nsarray to see if it is multihop response or 1
        if ([data count] > 2) { //multihop repsponse
            for (Peer *peer in _sessions) {
                if ([(NSData*)peer.key isEqualToData:(NSData*)[data objectAtIndex:1]]) {
   //                 [peer.peers addObject:[[Peer alloc] initWithKey:(__bridge SecKeyRef)([data objectAtIndex:2])]];
                }
            }
        } else if ([data count] <= 2) { //first order response
            [thisPeer resetAge];
            thisPeer.requestOut = NO;
            //forward requests to parents. we clear the parent list if all peers have returned
            if ([self updateParents]) {
                for (Peer *peer in _sessions) {
                    if (peer.isParent) {
                        NSError *error;
                        NSArray *Gossip = [[NSArray alloc] initWithObjects:@"Gossip", _appDelegate.cryptoManager.publicKey, [data objectAtIndex:1], nil];
                        NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:Gossip];
                        responseData = [_appDelegate.cryptoManager encrypt:responseData WithPublicKey:peer.key];
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
            Message *newMessage = [[Message alloc] initWithMessage:[data objectAtIndex:3] uID:[data objectAtIndex:2] fromLeader:NO];
            if ([data count] >= 5) {
                OSStatus status = [_appDelegate.cryptoManager verify:[[data objectAtIndex:3] dataUsingEncoding:NSUTF8StringEncoding] withSignature:[data objectAtIndex:4] andKey:_leadersPublicKey];
                if (status == 0) { //if verified...
                    newMessage.fromLeader = YES;
                }
            }
            [_allMessages setObject:newMessage forKey:[data objectAtIndex:1]];
            [_appDelegate.chatViewController addMessage:newMessage];
            for (Peer *peer in _sessions) {
                [self sendMessage:data toPeer:[_sessions objectForKey:peer]];
            }
        }
        else if (thisMessage.timer) { //if you sent the message and it had a timer, delete it.
            [thisMessage.timer invalidate];
            thisMessage.timer = nil;
        }
        else if (thisMessage) {
            return;
        }
        //[self forwardMessage:decryptedData];
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
        Peer *peer = [_sessions objectForKey:key];
        data = [_appDelegate.cryptoManager encrypt:data WithPublicKey:peer.key];
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

- (void)sendMessage:(Message*)message {
    NSString *time = [self getTimeString];
    NSString *toHash = [NSString stringWithFormat: @"%@%@%@", time, _userID, message.message];
    NSLog(@"%@", toHash);
    NSString *hash = [self MD5:toHash];
    [_allMessages setObject:message forKey:hash];
    NSArray *messageToSend;
    if (_leader) {
        NSData *messageData = [message.message dataUsingEncoding:NSUTF8StringEncoding];
        NSData *sig = [_appDelegate.cryptoManager sign:messageData withKey:_appDelegate.cryptoManager.privateKey];
        messageToSend = [NSArray arrayWithObjects:@"Message", hash, _userID, message.message, sig, nil];
    } else {
        messageToSend = [NSArray arrayWithObjects:@"Message", hash, _userID, message.message, nil];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:messageToSend];
    NSMutableArray *candidates = [NSMutableArray array];
    for (MCPeerID *key in _sessions) {
        if ([[[_sessions objectForKey:key] peers] count] > 0) {
            [candidates addObject:[_sessions objectForKey:key]];
        }
    }
    if ([candidates count] == 0) {
        NSArray *allPeers = [_sessions allValues];
        Peer *target = [allPeers objectAtIndex:arc4random() % allPeers.count];
        [self sendMessage:messageToSend toPeer:target];
    } else {
        Peer *firstHop = [candidates objectAtIndex:arc4random() % [candidates count]];
        Peer *secondHop = [firstHop.peers objectAtIndex:arc4random() % firstHop.peers.count];
        MCPeerID *secondHopPeerID = [secondHop.session.connectedPeers objectAtIndex:0];
        NSData *secondHopData = [_appDelegate.cryptoManager encrypt:data WithPublicKey:secondHop.key];
        //intermediate hop data is like [@"Forward", Public key to forward to, data]
        //we really should do 3 hops...
        NSArray *firstHopDataArray = [NSArray arrayWithObjects:@"Forward", secondHopPeerID, secondHopData, nil];
        NSData *firstHopData = [NSKeyedArchiver archivedDataWithRootObject:firstHopDataArray];
        firstHopData = [_appDelegate.cryptoManager encrypt:firstHopData WithPublicKey:firstHop.key];
        NSError *error;
        [firstHop.session sendData:firstHopData toPeers:firstHop.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
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