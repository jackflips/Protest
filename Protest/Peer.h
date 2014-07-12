//
//
//  Created by John Rogers on 4/12/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface Peer : NSObject

@property (nonatomic) SecKeyRef key;
@property (nonatomic, strong) NSMutableArray *peers;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic) CFAbsoluteTime age;
@property (nonatomic) BOOL requestOut;
@property (nonatomic) BOOL isParent;
@property (nonatomic) BOOL authenticated;
@property (nonatomic) BOOL isClient;
@property (nonatomic) SecKeyRef leadersKey;
@property (nonatomic, strong) NSString *protestName;

- (id)initWithSession:(MCSession*)session;
- (id)initWithName:(NSString*)displayName andPublicKey:(SecKeyRef)key;
- (void)resetAge;
- (CFAbsoluteTime)getAgeSinceReset;

@end
