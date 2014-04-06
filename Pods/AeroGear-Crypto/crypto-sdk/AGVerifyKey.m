/*
 * JBoss, Home of Professional Open Source.
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AGVerifyKey.h"
#import "AGUtil.h"
#import <libsodium-ios/sodium/crypto_sign_ed25519.h>


@implementation AGVerifyKey {
    NSData *_key;
}

- (id)initWithKey:(NSData *)key {
    NSParameterAssert(key != nil && [key length] == crypto_sign_ed25519_PUBLICKEYBYTES);
    
    self = [super init];
    if (self) {
        _key = key;
    }
    
    return self;
}

- (id)getKey {
    return _key;
}

- (BOOL)verify:(NSData *)message signature:(NSData *)signature {
    NSParameterAssert(message != nil);
    NSParameterAssert(signature != nil && [signature length] == crypto_sign_ed25519_BYTES);
    
    NSMutableData *signAndMsg = [NSMutableData data];
    [signAndMsg appendData:signature];
    [signAndMsg appendData:message];
    
    unsigned long long bufferLen;
    NSMutableData *newBuffer = [[NSMutableData alloc] initWithLength:signAndMsg.length];
    
    int status = crypto_sign_ed25519_open([newBuffer mutableBytes],
                                          &bufferLen,
                                          [signAndMsg bytes],
                                          signAndMsg.length,
                                          [_key bytes]);
    
    if( status != 0 ) {
        NSLog(@"Invalid signature %i", status);
        return NO;
    }
    
    return YES;
}

@end