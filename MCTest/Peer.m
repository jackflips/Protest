//
//
//  Created by John Rogers on 4/12/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "Peer.h"

@implementation Peer

- (void)resetAge {
    _age = CFAbsoluteTimeGetCurrent();
}

- (CFAbsoluteTime)getAgeSinceReset {
    return CFAbsoluteTimeGetCurrent() - _age;
}

- (id)initWithKey:(SecKeyRef)key andSession:(id)session {
    self = [super init];
    _key = key;
    _session = session;
    _peers = [[NSMutableArray alloc] init];
    _age = CFAbsoluteTimeGetCurrent();
    _requestOut = NO;
    _isParent = NO;
    return self;
}

- (id)initWithKey:(SecKeyRef)key {
    self = [super init];
    _key = key;
    _session = nil;
    _peers = [[NSMutableArray alloc] init];
    _age = CFAbsoluteTimeGetCurrent();
    _requestOut = NO;
    _isParent = NO;
    return self;
}


@end
