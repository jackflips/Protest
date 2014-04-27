//
//  Graph.h
//  MCTest
//
//  Created by John Rogers on 4/12/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface Graph : NSObject

@property (nonatomic, strong) NSData *key;
@property (nonatomic, strong) NSMutableArray *peers;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic) CFAbsoluteTime age;
@property (nonatomic) BOOL requestOut;
@property (nonatomic) BOOL isParent;

- (id)initWithKey:(NSData*)key andSession:(MCSession*)session;
- (id)initWithKey:(NSData*)key;
- (void)resetAge;
- (CFAbsoluteTime)getAgeSinceReset;

@end
