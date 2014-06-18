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
@property (nonatomic, copy) MCSession *session;
@property (nonatomic) CFAbsoluteTime age;
@property (nonatomic) BOOL requestOut;
@property (nonatomic) BOOL isParent;

- (id)initWithSession:(MCSession*)session;
- (void)resetAge;
- (CFAbsoluteTime)getAgeSinceReset;

@end
