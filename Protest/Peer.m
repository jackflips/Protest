//
//
//  Created by John Rogers on 4/12/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "Peer.h"
#import "MimicManager.h"

@interface Peer()

@end

@implementation Peer

- (void)resetAge {
    _age = CFAbsoluteTimeGetCurrent();
}

- (CFAbsoluteTime)getAgeSinceReset {
    return CFAbsoluteTimeGetCurrent() - _age;
}

- (id)initWithSession:(MCSession*)session {
    self = [super init];
    _session = session;
    _peers = [NSMutableArray array];
    _age = CFAbsoluteTimeGetCurrent();
    _authenticated = NO;
    return self;
}

- (id)initWithName:(NSString*)displayName andPublicKey:(SecKeyRef)key {
    self = [super init];
    _peers = [NSMutableArray array];
    _age = CFAbsoluteTimeGetCurrent();
    _displayName = displayName;
    _key = key;
    _authenticated = NO;
    return self;
}

@end
