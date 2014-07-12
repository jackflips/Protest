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
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _password = nil;
        _nameOfProtest = nil;
        _foundProtests = [NSMutableDictionary dictionary];
        
        //create random username
        _userID = [[NSMutableString alloc] init];
        NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        for (int i=0; i<12; i++) {
            [_userID appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((u_int32_t)[letters length]) % [letters length]]];
        }
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
    
    NSData *key = [_appDelegate.cryptoManager getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey];
    NSData *signedData = [_appDelegate.cryptoManager sign:testData withKey:_appDelegate.cryptoManager.privateKey];
    OSStatus *status = [_appDelegate.cryptoManager verify:testData withSignature:signedData andKey:_appDelegate.cryptoManager.publicKey];
    NSLog(@"%i", status);
    
}

- (void)startProtest:(NSString*)name password:(NSString*)password {
    NSLog(@"manager gonna browse");
    _nameOfProtest = name;
    _password = password;
    _leadersPublicKey = _appDelegate.cryptoManager.publicKey;
    _peerID = [[MCPeerID alloc] initWithDisplayName:_userID];
    [self browse];
}

- (void)browse {
    _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID serviceType:@"Protest"];
    [_browser setDelegate:self];
    [_browser startBrowsingForPeers];
}

- (void)searchForProtests {
    _peerID = [[MCPeerID alloc] initWithDisplayName:_userID];
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
    for (NSString *displayName in _foundProtests) {
        if ([[[_foundProtests objectForKey:displayName] protestName] isEqualToString:protestName]) {
            if (password) {
                [self sendMessage:@[@"WantsToConnect", password] toPeer:[_foundProtests objectForKey:displayName]];
                _password = password;
            } else {
                [self sendMessage:@[@"WantsToConnect"] toPeer:[_foundProtests objectForKey:displayName]];
            }
        }
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"didn't start browsing for peers");
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    Peer *newPeer = [[Peer alloc] initWithSession:[[MCSession alloc] initWithPeer:_peerID
                                                                 securityIdentity:nil
                                                             encryptionPreference:MCEncryptionNone]];
    newPeer.session.delegate = self;
    newPeer.peerID = peerID;
    [_foundProtests setObject:newPeer forKey:peerID.displayName];
    NSArray *publicKeyArray = @[[_appDelegate.cryptoManager getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey]];
    NSData *publicKeyContext = [NSKeyedArchiver archivedDataWithRootObject:publicKeyArray];
    [browser invitePeer:peerID toSession:newPeer.session withContext:publicKeyContext timeout:120.0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"browser lost peer");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser fucked up");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    Peer *newPeer = [[Peer alloc] initWithSession:[[MCSession alloc] initWithPeer:_peerID
                                                                 securityIdentity:nil
                                                             encryptionPreference:MCEncryptionNone]];
    newPeer.session.delegate = self;
    newPeer.peerID = peerID;
    newPeer.isClient = YES;
    newPeer.key = [_appDelegate.cryptoManager addPublicKey:[[NSKeyedUnarchiver unarchiveObjectWithData:context] objectAtIndex:0] withTag:peerID.displayName];
    [_foundProtests setObject:newPeer forKey:peerID.displayName];
    invitationHandler(YES, newPeer.session);
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"peer did change state: %ld", state);
    if (state == MCSessionStateConnected) {
        NSLog(@"connected");
        Peer *peer = [_foundProtests objectForKey:peerID.displayName];
        if (peer.isClient) {
            NSError *error;
            NSArray *message = @[@"Handshake", [_appDelegate.cryptoManager getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey]];
            NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
            NSData *encryptedMessage = [_appDelegate.cryptoManager encrypt:messageData WithPublicKey:peer.key];
            [peer.session sendData:encryptedMessage toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&error];
        }
    } else if (state == MCSessionStateNotConnected) {
        Peer *peer = [_foundProtests objectForKey:peerID.displayName];
        if (peer) [_foundProtests removeObjectForKey:peerID.displayName];
        else peer = [_sessions objectForKey:peerID.displayName];
        if (peer) {
            [_appDelegate.viewController removeProtestFromList:peer.protestName];
            [_sessions removeObjectForKey:peerID.displayName];
            [self sendDisconnectEvent:peer];
        }
    }
}

- (void)traversePeersHelper:(Peer*)peer func:(void (^)(Peer*))fn counter:(int)counter {
    if (counter < 3) {
        fn(peer);
        for (Peer *peersPeer in peer.peers) {
            [self traversePeersHelper:peersPeer func:fn counter:counter+1];
        }
    }
}

- (void)traversePeers:(void (^)(Peer*))fn { //applys fn to all peers up to 3 levels deep
    for (Peer *peer in [_sessions allValues]) {
        [self traversePeersHelper:peer func:fn counter:0];
    }
}

- (void)sendConnectEvent:(Peer*)peer {
    [self sendEventToAllPeers:@[@"PeerConnected",
                               @[_userID, [_appDelegate.cryptoManager getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey]],
                                @[peer.peerID.displayName, [_appDelegate.cryptoManager getPublicKeyBitsFromKey:peer.key]], [NSNumber numberWithInt:0]] except:peer];
}

- (void)sendDisconnectEvent:(Peer*)peer {
    [self sendEventToAllPeers:@[@"PeerDisconnected", @[_userID, peer.peerID.displayName], [NSNumber numberWithInt:0]] except:peer];
}

- (void)sendEventToAllPeers:(NSArray*)event except:(Peer*)exclusion {
    for (Peer *peer in [_sessions allValues]) {
        if (peer != exclusion) {
            [self sendMessage:event toPeer:peer];
        }
    }
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
        NSData *leadersKeyData = [_appDelegate.cryptoManager getPublicKeyBitsFromKey:_leadersPublicKey];
        NSArray *handshake2 = @[@"HandshakeBack", _nameOfProtest, [NSNumber numberWithBool:isPassword], leadersKeyData];
        [self sendMessage:handshake2 toPeer:thisPeer];
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"HandshakeBack"]) {
        if (_nameOfProtest
            && [[data objectAtIndex:1] isEqualToString:_nameOfProtest]
            && [[data objectAtIndex:3] isEqualToData:[_appDelegate.cryptoManager getPublicKeyBitsFromKey:_leadersPublicKey]])
        {
            [self sendMessage:@[@"WantsToConnect", _password] toPeer:[_foundProtests objectForKey:thisPeer.peerID.displayName]];
        }
        else {
            thisPeer.protestName = [data objectAtIndex:1];
            thisPeer.leadersKey = [_appDelegate.cryptoManager addPublicKey:[data objectAtIndex:3] withTag:thisPeer.peerID.displayName];;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [_appDelegate.viewController addProtestToList:[data objectAtIndex:1] password:[[data objectAtIndex:2] boolValue] health:1];
            }];
        }
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"WantsToConnect"]) {
        if (_password) {
            if ([[data objectAtIndex:1] isEqualToString:_password]) {
                [self sendMessage:@[@"Connected"] toPeer:thisPeer];
                [_sessions setObject:thisPeer forKey:thisPeer.peerID.displayName];
                [_foundProtests removeObjectForKey:thisPeer.peerID.displayName];
                [self sendConnectEvent:thisPeer];
            } else {
                [self sendMessage:@[@"WrongPassword"] toPeer:thisPeer];
            }
        } else {
            [self sendMessage:@[@"Connected"] toPeer:thisPeer];
            [_sessions setObject:thisPeer forKey:thisPeer.peerID.displayName];
            [_foundProtests removeObjectForKey:thisPeer.peerID.displayName];
            [self sendConnectEvent:thisPeer];
            
        }
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"WrongPassword"]) {
        [_appDelegate.viewController reset];
        [_appDelegate.chatViewController dismissViewControllerAnimated:YES completion:nil];
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Incorrect Password"
                                                          message:@"Your password was incorrect."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
        _password = nil;
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"Connected"]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_appDelegate.chatViewController chatLoaded:thisPeer.protestName];
        }];
        [_sessions setObject:thisPeer forKey:thisPeer.peerID.displayName];
        [_foundProtests removeObjectForKey:thisPeer.peerID.displayName];
        _leadersPublicKey = thisPeer.leadersKey;
        _nameOfProtest = thisPeer.protestName;
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"PeerConnected"]) {
        //protocol: [0: @"PeerConnected", 1: [Peer 1's displayName, publicKey], 2: [Peer 2's displayName, publicKey], 3:counter
        int counter = (int)[[data objectAtIndex:3] integerValue];
        if (counter < 3) {
            [self traversePeers:^(Peer* peer){
                if ([peer.displayName isEqualToString:[[data objectAtIndex:1] objectAtIndex:0]] &&
                    ![_userID isEqualToString:[[data objectAtIndex:1] objectAtIndex:0]]) {
                    for (Peer *peersPeer in peer.peers) {
                        if ([peersPeer.displayName isEqualToString:[[data objectAtIndex:1] objectAtIndex:0]]) {
                            return;
                        }
                    }
                    NSString *newPeerDisplayName = [[data objectAtIndex:1] objectAtIndex:0];
                    Peer *newPeer = [[Peer alloc] initWithName:newPeerDisplayName andPublicKey:[_appDelegate.cryptoManager addPublicKey:[[data objectAtIndex:1] objectAtIndex:1] withTag:newPeerDisplayName]];
                    [peer.peers addObject:newPeer];
                }
            }];
            if (counter < 2) {
                NSMutableArray *dataCopy = [NSMutableArray arrayWithArray:data];
                [dataCopy setObject:[NSNumber numberWithInt:counter+1] atIndexedSubscript:3];
                [self sendEventToAllPeers:dataCopy except:thisPeer];
            }
        }
    }
    
    if ([[data objectAtIndex:0] isEqualToString:@"PeerDisconnected"]) {
        //protocol: @[@"PeerDisconnected", @[_userID, peer.displayName], counter]
        int counter = (int)[[data objectAtIndex:3] integerValue];
        if (counter < 3) {
            [self traversePeers:^(Peer* peer){
                if ([peer.displayName isEqualToString:[[data objectAtIndex:1] objectAtIndex:0]]&&
                    ![_userID isEqualToString:[[data objectAtIndex:1] objectAtIndex:0]]) {
                    NSString *peersDisplayName = [[data objectAtIndex:1] objectAtIndex:1];
                    for (Peer *peersPeer in peer.peers) {
                        if ([peersPeer.displayName isEqualToString:peersDisplayName]) {
                            [peer.peers removeObject:peersPeer];
                        }
                    }
                }
            }];
            if (counter < 2) {
                NSMutableArray *dataCopy = [NSMutableArray arrayWithArray:data];
                [dataCopy setObject:[NSNumber numberWithInt:counter+1] atIndexedSubscript:2];
                [self sendEventToAllPeers:dataCopy except:thisPeer];
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