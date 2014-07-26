//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ConnectionManager.h"
#import "ChatViewController.h"
#import "AppDelegate.h"

@interface ConnectionManager()

@property (nonatomic, retain) AppDelegate *appDelegate;

@end

@implementation ConnectionManager

static const double PRUNE = 30.0;

- (id)init{
    self = [super init];
    
    if (self) {
        srand(time(NULL));
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
        _secretMessagePath = [NSMutableArray array];
        _state = ProtestNetworkStateNotConnected;
        DIAGNOSTIC_ADDRESS =  @"http://107.170.255.118:8000";
        
        //create random username
        _userID = [self randomString:12];
        
        //[self sendDiagnosticMessage:[NSString stringWithFormat:@"event=connection&peer=%@&connectedpeer=%@", _userID, @"123"]];
        
    }
    return self;
}

- (NSString*)randomString:(int)length {
    NSMutableString *str = [[NSMutableString alloc] init];
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int i=0; i<length; i++) {
        [str appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((u_int32_t)[letters length]) % [letters length]]];
    }
    return str;
}

- (void)disconnectFromPeers {
    for (id key in _sessions) {
        Peer *peer = [_sessions objectForKey:key];
        [peer.session disconnect];
    }
}

- (void)sendDiagnosticMessage:(NSString*)requestData {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                             [NSURL URLWithString:DIAGNOSTIC_ADDRESS]];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = requestData;
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               if (connectionError) {
                                   NSLog(@"error: %@", connectionError);
                               }
                           }];
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
    _state = ProtestNetworkStateConnected;
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
            Peer *peer = [_foundProtests objectForKey:displayName];
            NSString *keyFrag2 = [self randomString:32];
            peer.symmetricKey = [self MD5:[NSString stringWithFormat: @"%@%@", peer.symmetricKeyFragment, keyFrag2]];
            if (password) {
                [self sendMessage:@[@"WantsToConnect", password, keyFrag2] toPeer:peer];
                _password = password;
            } else {
                [self sendMessage:@[@"WantsToConnect", keyFrag2] toPeer:peer];
            }
        }
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"didn't start browsing for peers");
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    if (![_foundProtests objectForKey:peerID.displayName] && ![_sessions objectForKey:peerID.displayName]) {
        Peer *newPeer = [[Peer alloc] initWithSession:[[MCSession alloc] initWithPeer:_peerID
                                                                     securityIdentity:nil
                                                                 encryptionPreference:MCEncryptionNone]];
        newPeer.session.delegate = self;
        newPeer.peerID = peerID;
        newPeer.displayName = peerID.displayName;
        
        [_foundProtests setObject:newPeer forKey:peerID.displayName];
        NSArray *publicKeyArray = @[[_appDelegate.cryptoManager getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey]];
        NSData *publicKeyContext = [NSKeyedArchiver archivedDataWithRootObject:publicKeyArray];
        [browser invitePeer:peerID toSession:newPeer.session withContext:publicKeyContext timeout:120.0];
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"browser lost peer");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"advertiser fucked up");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession *session))invitationHandler {
    if (![_foundProtests objectForKey:peerID.displayName] && ![_sessions objectForKey:peerID.displayName]) {
        Peer *newPeer = [[Peer alloc] initWithSession:[[MCSession alloc] initWithPeer:_peerID
                                                                     securityIdentity:nil
                                                                 encryptionPreference:MCEncryptionNone]];
        newPeer.session.delegate = self;
        newPeer.peerID = peerID;
        newPeer.isClient = YES;
        newPeer.key = [_appDelegate.cryptoManager addPublicKey:[[NSKeyedUnarchiver unarchiveObjectWithData:context] objectAtIndex:0] withTag:peerID.displayName];
        newPeer.displayName = peerID.displayName;
        [_foundProtests setObject:newPeer forKey:peerID.displayName];
        invitationHandler(YES, newPeer.session);
    }
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
        if (_appDelegate.DIAGNOSTIC_MODE) {
            [self sendDiagnosticMessage:[NSString stringWithFormat:@"protest=%@&event=disconnected&peer=%@&connectedpeer=%@", _nameOfProtest, _userID, peerID.displayName]];
        }
        Peer *peer = [_foundProtests objectForKey:peerID.displayName];
        if (peer) [_foundProtests removeObjectForKey:peerID.displayName];
        else peer = [_sessions objectForKey:peerID.displayName];
        if (peer) {
            [_appDelegate.viewController removeProtestFromList:peer.protestName];
            [_sessions removeObjectForKey:peerID.displayName];
            [self traversePeers:^(Peer *myPeer, Peer *parent){
                for (int i=0; i<myPeer.peers.count; i++) {
                    if ([[myPeer.peers[i] displayName] isEqualToString:myPeer.displayName]) {
                        [myPeer.peers removeObjectAtIndex:i];
                    }
                }
            }];
            [self sendDisconnectEvent:peer];
        }
    }
}



- (void)traversePeersHelper:(Peer*)peer func:(void (^)(Peer*, Peer*))fn counter:(int)counter parent:(Peer*)parent {
    if (counter < 3) {
        fn(peer, parent);
        for (Peer *peersPeer in peer.peers) {
            [self traversePeersHelper:peersPeer func:fn counter:counter+1 parent:peer];
        }
    }
}

- (void)traversePeers:(void (^)(Peer*, Peer*))fn { //applys fn to all peers up to 3 levels deep
    for (Peer *peer in [_sessions allValues]) {
        [self traversePeersHelper:peer func:fn counter:0 parent:nil];
    }
}

- (void)sendConnectEvent:(Peer*)peer {
    [self sendEventToAllPeers:@[@"PeerConnected",
                               @[_userID, [_appDelegate.cryptoManager getPublicKeyBitsFromKey:_appDelegate.cryptoManager.publicKey]],
                                @[peer.peerID.displayName, [_appDelegate.cryptoManager getPublicKeyBitsFromKey:peer.key]], [NSNumber numberWithInt:0]] except:peer];
}

- (void)sendDisconnectEvent:(Peer*)peer {
    if (![peer.displayName isEqualToString:_userID]) {
        [self sendEventToAllPeers:@[@"PeerDisconnected", @[_userID, peer.peerID.displayName], [NSNumber numberWithInt:0]] except:peer];
    }
    
}

- (void)sendEventToAllPeers:(NSArray*)event except:(Peer*)exclusion {
    for (Peer *peer in [_sessions allValues]) {
        if (peer != exclusion) {
            NSLog(@"%@ %@", peer, exclusion);
            [self sendMessage:event toPeer:peer];
        }
    }
}

- (void)startMimicTraffic:(Peer*)peer {
    peer.mimicManager = [[MimicManager alloc] initAndSendMimicWithConnectionManager:self andPeer:peer];
}

- (void)firstMimic:(Peer*)peer {
    peer.mimicManager = [[MimicManager alloc] initWithConnectionManager:self andPeer:peer];
}

- (NSArray*)getPeerlist {
    NSMutableArray *peerlist = [NSMutableArray array];
    for (Peer *peer in [_sessions allValues]) {
        if (peer.authenticated) {
            [peerlist addObject:@[peer.displayName, [_appDelegate.cryptoManager getPublicKeyBitsFromKey:peer.key]]];
            for (Peer *peersPeer in peer.peers) {
                [peerlist addObject:@[peersPeer.displayName, [_appDelegate.cryptoManager getPublicKeyBitsFromKey:peersPeer.key]]];
            }
            [peerlist addObject:@[@"stop"]];
        }
    }
    return peerlist;
}

- (void)addPeerlist:(NSArray*)peerlist currentPeer:(Peer*)thisPeer {
    Peer *parentPeer = nil;
    for (NSArray *peerInfo in peerlist) {
        NSString *newPeerName = [peerInfo objectAtIndex:0];
        if ([newPeerName isEqualToString:@"stop"]) {
            parentPeer = nil;
            continue;
        }
        NSData *newPeerKey = [peerInfo objectAtIndex:1];
        Peer *newPeer = [[Peer alloc] initWithName:newPeerName andPublicKey:[_appDelegate.cryptoManager addPublicKey:newPeerKey withTag:newPeerName]];
        if (!parentPeer) {
            [thisPeer.peers addObject:newPeer];
            parentPeer = newPeer;
        } else {
            [parentPeer.peers addObject:newPeer];
        }
    }
}

- (NSData*)padMessage:(NSData*)message lengthToPadTo:(int)kLength {
    int messageLength = message.length;
    NSData *prefix = [NSData dataWithBytes:&messageLength length: sizeof(int)];
    u_int8_t prefixData[sizeof(int)];
    [prefix getBytes:prefixData length:sizeof(int)];
    Byte bytes[messageLength];
    [message getBytes:bytes length:messageLength];
    
    u_int8_t newMessageData[kLength];
    for (int i=0; i<kLength; i++) {
        if (i<4) {
            newMessageData[i] = prefixData[i];
        } else if (i < messageLength + 4) {
            newMessageData[i] = bytes[i-4];
        }
        else {
            u_int8_t garbage = rand() % 256;
            newMessageData[i] = garbage;
        }
    }
    return [NSData dataWithBytes:newMessageData length:kLength];
}

- (void)sendMessage:(id)message toPeer:(Peer*)peer {
    NSError *error;
    NSData *messageData;
    if ([message isKindOfClass:[NSArray class]]) {
        for (id __strong thing in message) {
            if ([thing isKindOfClass:[NSString class]]) {
                thing = [thing dataUsingEncoding:NSUTF8StringEncoding];
            }
        }
        messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    } else if ([message isKindOfClass:[NSData class]]) {
        messageData = message;
    }
    NSData *encryptedMessage;
    if (peer.authenticated) {
        NSData *newMessageData = [self padMessage:(NSData*)messageData lengthToPadTo:2000];
        encryptedMessage = [_appDelegate.cryptoManager encrypt:newMessageData password:peer.symmetricKey];
    } else {
        encryptedMessage = [_appDelegate.cryptoManager encrypt:messageData WithPublicKey:peer.key];
    }
    [peer.session sendData:encryptedMessage toPeers:@[peer.peerID] withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
}

- (void)sendMessageWithoutEncrypting:(id)message toPeer:(Peer*)peer {
    NSError *error;
    NSData *messageData;
    if ([message isKindOfClass:[NSArray class]]) {
        messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    } else if ([message isKindOfClass:[NSData class]]) {
        messageData = message;
    }
    [peer.session sendData:messageData toPeers:@[peer.peerID] withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)messageData fromPeer:(MCPeerID *)peerID{
    @try {
        Peer *thisPeer = [_sessions objectForKey:peerID.displayName];
        if (thisPeer == nil) thisPeer = [_foundProtests objectForKey:peerID.displayName];
        NSData *decryptedData;
        NSArray *data;
        @try {
            if (thisPeer.authenticated) {
                NSData *decryptedBytes = [_appDelegate.cryptoManager decrypt:messageData password:thisPeer.symmetricKey];
                int messageLength;
                [decryptedBytes getBytes:&messageLength length:4];
                if (messageLength <= 1996) {
                    Byte bytes[messageLength];
                    [decryptedBytes getBytes:bytes range:NSMakeRange(4, messageLength)];
                    decryptedData = [NSData dataWithBytes:bytes length:messageLength];
                }
            } else {
                decryptedData = [_appDelegate.cryptoManager decrypt:messageData];
            }
            @try {
                data = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            }
            @catch (NSException *exception) {
                decryptedData = [_appDelegate.cryptoManager decrypt:decryptedData];
            }
            data = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            /*
            if (![[data objectAtIndex:0] isEqualToString:@"Mimic"]) {
                NSLog(@"%@", data);
            }
            */
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
            return;
        }
        
        if ([[data objectAtIndex:0] isEqualToString:@"Handshake"]) {
            thisPeer.key = [_appDelegate.cryptoManager addPublicKey:[data objectAtIndex:1] withTag:peerID.displayName];
            BOOL isPassword = NO;
            if (_password) isPassword = YES;
            NSData *leadersKeyData = [_appDelegate.cryptoManager getPublicKeyBitsFromKey:_leadersPublicKey];
            thisPeer.symmetricKeyFragment = [self randomString:32];
            NSArray *handshake2 = @[@"HandshakeBack", _nameOfProtest, [NSNumber numberWithBool:isPassword], leadersKeyData, thisPeer.symmetricKeyFragment];
            [self sendMessage:handshake2 toPeer:thisPeer];
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"HandshakeBack"]) {
            if ([_foundProtests objectForKey:thisPeer.displayName]) {
                thisPeer.symmetricKeyFragment = [data objectAtIndex:4];
                if (_nameOfProtest
                    && [[data objectAtIndex:1] isEqualToString:_nameOfProtest]
                    && [[data objectAtIndex:3] isEqualToData:[_appDelegate.cryptoManager getPublicKeyBitsFromKey:_leadersPublicKey]])
                {
                    NSString *keyFrag2 = [self randomString:32];
                    thisPeer.symmetricKey = [self MD5:[NSString stringWithFormat: @"%@%@", thisPeer.symmetricKeyFragment, keyFrag2]];
                    [self sendMessage:@[@"WantsToConnect", _password, keyFrag2] toPeer:[_foundProtests objectForKey:thisPeer.displayName]];
                }
                else {
                    thisPeer.protestName = [data objectAtIndex:1];
                    thisPeer.leadersKey = [_appDelegate.cryptoManager addPublicKey:[data objectAtIndex:3] withTag:thisPeer.peerID.displayName];
                    thisPeer.displayName = thisPeer.peerID.displayName;
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [_appDelegate.viewController addProtestToList:[data objectAtIndex:1] password:[[data objectAtIndex:2] boolValue] health:1];
                    }];
                }
            }
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"WantsToConnect"]) {
            if ([_foundProtests objectForKey:thisPeer.displayName]) {
                if (!_password || (_password && [[data objectAtIndex:1] isEqualToString:_password])) {
                    thisPeer.symmetricKey = [self MD5:[NSString stringWithFormat: @"%@%@", thisPeer.symmetricKeyFragment, [data objectAtIndex:1]]];
                    [self sendMessage:@[@"Connected", [self getPeerlist]] toPeer:thisPeer];
                    [_sessions setObject:thisPeer forKey:thisPeer.peerID.displayName];
                    [_foundProtests removeObjectForKey:thisPeer.peerID.displayName];
                } else {
                    [self sendMessage:@[@"WrongPassword"] toPeer:thisPeer];
                    [thisPeer.session disconnect];
                    [_foundProtests removeObjectForKey:thisPeer.displayName];
                }
            }
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"WrongPassword"]) {
            if (_state == ProtestNetworkStateNotConnected) {
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
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"Connected"]) {
            NSArray *peerData = [data objectAtIndex:1];
            [self addPeerlist:peerData currentPeer:thisPeer];
            [_sessions setObject:thisPeer forKey:thisPeer.peerID.displayName];
            [_foundProtests removeObjectForKey:thisPeer.peerID.displayName];
            if (_state == ProtestNetworkStateNotConnected) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [_appDelegate.chatViewController chatLoaded:thisPeer.protestName];
                }];
                _leadersPublicKey = thisPeer.leadersKey;
                _nameOfProtest = thisPeer.protestName;
                [self browse];
                _state = ProtestNetworkStateConnected;
            }
            [self sendDiagnosticMessage:[NSString stringWithFormat:@"protest=%@&event=connected&peer=%@&connectedpeer=%@", _nameOfProtest, _userID, thisPeer.displayName]];
            [self sendMessage:@[@"Ack"] toPeer:thisPeer];
            thisPeer.authenticated = YES;
        }
        
        else if ([([data objectAtIndex:0]) isEqualToString:@"Ack"]) {
            thisPeer.authenticated = YES;
            [self sendConnectEvent:thisPeer];
            [self startMimicTraffic:thisPeer];
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"Mimic"]) {
            if (thisPeer.mimicManager) {
                [thisPeer.mimicManager recievedMimic];
            } else {
                [self firstMimic:thisPeer];
            }
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"PeerConnected"]) {
            //protocol: [0: @"PeerConnected", 1: [Peer 1's displayName, publicKey], 2: [Peer 2's displayName, publicKey], 3:counter
            if (_state == ProtestNetworkStateConnected &&
                [_sessions objectForKey:thisPeer.displayName] &&
                ![_userID isEqualToString:data[1][0]] &&
                ![_userID isEqualToString:data[2][0]])
                {
                int counter = (int)[[data objectAtIndex:3] integerValue];
                if (counter < 3) {
                    [self traversePeers:^(Peer* peer, Peer* parent){
                        if ([peer.displayName isEqualToString:data[1][0]])
                        {
                            NSString *newPeerDisplayName = data[2][0];
                            if (![parent.displayName isEqualToString:newPeerDisplayName]) {
                                if (![parent.peers containsObject:newPeerDisplayName]) {
                                    Peer *newPeer = [[Peer alloc] initWithName:newPeerDisplayName andPublicKey:[_appDelegate.cryptoManager addPublicKey:data[2][1] withTag:newPeerDisplayName]];
                                    [peer.peers addObject:newPeer];
                                }
                            }
                        } else if ([peer.displayName isEqualToString:data[2][0]]) {
                            NSString *newPeerDisplayName = data[1][0];
                            if (![parent.displayName isEqualToString:newPeerDisplayName]) {
                                if (![parent.peers containsObject:newPeerDisplayName]) {
                                    Peer *newPeer = [[Peer alloc] initWithName:newPeerDisplayName andPublicKey:[_appDelegate.cryptoManager addPublicKey:data[1][1] withTag:newPeerDisplayName]];
                                    [peer.peers addObject:newPeer];
                                }
                            }
                        }
                    }];
                    NSLog(@"Peer %@ -> Peer %@", data[1][0], data[2][0]);
                    [self printSessions];
                    if (counter < 2) {
                        NSMutableArray *dataCopy = [NSMutableArray arrayWithArray:data];
                        [dataCopy setObject:[NSNumber numberWithInt:counter+1] atIndexedSubscript:3];
                        [self sendEventToAllPeers:dataCopy except:thisPeer];
                    }
                }
            }
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"PeerDisconnected"]) {
            //protocol: @[@"PeerDisconnected", @[_userID, peer.displayName], counter]
            if (_state == ProtestNetworkStateConnected && [_sessions objectForKey:thisPeer.displayName]) {
                int counter = (int)[[data objectAtIndex:2] integerValue];
                if (counter < 3) {
                    [self traversePeers:^(Peer *peer, Peer *parent){
                        if ([peer.displayName isEqualToString:data[1][0]] &&
                            ![_userID isEqualToString:data[1][0]]) {
                            NSString *peersDisplayName = data[1][1];
                            for (int i=0; i<peer.peers.count; i++) {
                                if ([[peer.peers[i] displayName] isEqualToString:peersDisplayName]) {
                                    [peer.peers removeObjectAtIndex:i];
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
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"Message"]) {
            if (_state == ProtestNetworkStateConnected) {
                Message *thisMessage = [_allMessages objectForKey:data[1]];
                if (!thisMessage) {
                    Message *newMessage = [[Message alloc] initWithMessage:[data objectAtIndex:3] uID:[data objectAtIndex:2] fromLeader:NO];
                    if ([data count] >= 5) {
                        OSStatus status = [_appDelegate.cryptoManager verify:[[data objectAtIndex:3] dataUsingEncoding:NSUTF8StringEncoding] withSignature:[data objectAtIndex:4] andKey:_leadersPublicKey];
                        if (status == 0) { //if verified...
                            newMessage.fromLeader = YES;
                        }
                    }
                    [_allMessages setObject:newMessage forKey:[data objectAtIndex:1]];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [_appDelegate.chatViewController addMessage:newMessage];
                    }];
                    for (Peer *peer in [_sessions allValues]) {
                        [self sendMessage:data toPeer:peer];
                    }
                }
                else if (thisMessage.timer) { //if you sent the message and it had a timer, delete it.
                    [thisMessage.timer invalidate];
                    thisMessage.timer = nil;
                }
                else if (thisMessage) {
                    return;
                }
            }
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"Forward"]) {
            if (_state == ProtestNetworkStateConnected && [_sessions objectForKey:thisPeer.displayName]) {
                [self sendMessage:data[2] toPeer:[self returnPeerGivenName:data[1]]];
            }
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"Census"]) {
            NSNumber *counter = [data objectAtIndex:1];
            if (_leader == NO) {
                NSUInteger randomIndex = arc4random() % [[_sessions allValues] count];
                Peer *peer = [[_sessions allValues] objectAtIndex:randomIndex];
                [self sendMessage:@[@"Census", @([counter intValue] + 1)] toPeer:peer];
            } else {
                [self censusReturned:[counter intValue]];
            }
        }
        
        else if ([[data objectAtIndex:0] isEqualToString:@"CensusReport"]) {
            int newNetworkSize = [[data objectAtIndex:1] intValue];
            if (networkSize != newNetworkSize) {
                networkSize = newNetworkSize;
                for (Peer *peer in [_sessions allValues]) {
                    [self sendMessage:data toPeer:peer];
                }
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"CRASH: %@", exception);
        NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
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

- (void)printSessions {
    for (Peer *peer in [_sessions allValues]) {
        NSLog(@"%@", peer.displayName);
        for (Peer *peersPeer in peer.peers) {
            NSLog(@"    %@", peersPeer.displayName);
            for (Peer *peersPeersPeer in peersPeer.peers) {
                NSLog(@"        %@", peersPeersPeer.displayName);
            }
        }
    }
}

- (Peer*)peerExists:(NSArray*)peers name:(NSString*)displayName {
    for (Peer *peer in peers) {
        if ([peer.displayName isEqualToString:displayName]) return peer;
    }
    return nil;
}

- (Peer*)returnPeerGivenName:(NSString*)name currentLevel:(NSArray*)level {
    for (Peer *peer in level) {
        if ([name isEqualToString:peer.displayName]) {
            return peer;
        }
    }
    for (Peer *peer in level) {
        if (peer.peers) {
            Peer *possiblePeer = [self returnPeerGivenName:name currentLevel:peer.peers];
            if (possiblePeer) {
                return possiblePeer;
            }
        }
    }
    return nil;
}

- (Peer*)returnPeerGivenName:(NSString*)name {
    return [self returnPeerGivenName:name currentLevel:[_sessions allValues]];
}

- (BOOL)pathStillValid {
    NSArray *currentLevel = [_sessions allValues];
    for (NSString *name in _secretMessagePath) {
        Peer *peer = [self peerExists:currentLevel name:name];
        if (name == _secretMessagePath.lastObject) {
            return YES;
        } else if (peer.peers) {
            currentLevel = peer.peers;
        } else {
            return NO;
        }
    }
    return NO;
}

- (void)findAllPathsThroughPeerTreeHelper:(NSArray*)level andWorkingPath:(NSMutableArray*)path paths:(NSMutableArray*)paths {
    for (Peer *peer in level) {
        NSMutableArray *newPath = [NSMutableArray arrayWithArray:path];
        [newPath addObject:peer];
        [paths removeObject:path];
        [paths addObject:newPath];
        if (peer.peers) {
            [self findAllPathsThroughPeerTreeHelper:peer.peers andWorkingPath:newPath paths:paths];
        }
    }
}

- (NSArray*)findAllPathsThroughPeerTree {
    NSMutableArray *paths = [NSMutableArray array];
    NSArray *validPeers = [[_sessions allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [object authenticated] == YES;
    }]];
    [self findAllPathsThroughPeerTreeHelper:validPeers andWorkingPath:[NSMutableArray array] paths:paths];
    int highestCount = 0;
    for (NSArray *path in paths) {
        if (path.count > highestCount) highestCount = (int)path.count;
    }
    for (int i=0; i<paths.count; i++) {
        if ([paths[i] count] < highestCount) [paths removeObjectAtIndex:i];
        for (int j=0; j<[paths[i] count]; j++) {
            paths[i][j] = [paths[i][j] displayName];
        }
        
    }
    return paths;
}

- (void)generateNewPath {
    NSArray *paths = [self findAllPathsThroughPeerTree];
    _secretMessagePath = paths[arc4random() % paths.count];
}

- (NSData*)encryptMessageGivenPath:(NSData*)message andPath:(NSArray*)path {
    if (path.count > 1) {
        NSString *name = path.lastObject;
        SecKeyRef key = [[self returnPeerGivenName:name] key];
        NSArray *msg = @[@"Forward", name, [_appDelegate.cryptoManager encrypt:message WithPublicKey:key]];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:msg];
        return [self encryptMessageGivenPath:data andPath:[path subarrayWithRange:NSMakeRange(0, path.count-1)]];
    } else {
        return message;
    }
}

- (void)sendMessageAlongPath:(NSData*)data {
    NSString *name = _secretMessagePath.firstObject;
    Peer *peer = [self returnPeerGivenName:name];
    NSData *dataToSend = [self encryptMessageGivenPath:data andPath:_secretMessagePath];
    NSLog(@"true path:");
    for (NSString *hop in _secretMessagePath) {
        NSLog(@"%@", hop);
    }
    [self sendMessage:dataToSend toPeer:peer];
}

- (void)sendMessage:(Message*)message {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSLog(@"current peers:");
        [self printSessions];
        NSString *time = [self getTimeString];
        NSString *toHash = [NSString stringWithFormat: @"%@%@%@", time, _userID, message.message];
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
        
        
        if ([self pathStillValid]) {
            [self sendMessageAlongPath:data];
        } else {
            [self generateNewPath];
            [self sendMessageAlongPath:data];
        }
    }];
}

- (void)conductCensus {
    NSUInteger randomIndex = arc4random() % [[_sessions allValues] count];
    Peer *peer = [[_sessions allValues] objectAtIndex:randomIndex];
    [self sendMessage:@[@"Census", [NSNumber numberWithInt:0]] toPeer:peer];
    censusOut = YES;
}

- (void)censusReturned:(int)counter {
    networkSize = (networkSize + counter)/2;
    for (Peer *peer in [_sessions allValues]) {
        [self sendMessage:@[@"CensusReport", [NSNumber numberWithInt:networkSize]] toPeer:peer];
    }
    [self conductCensus];
}

@end