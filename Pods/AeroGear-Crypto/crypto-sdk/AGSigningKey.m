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

#import "AGSigningKey.h"
#import "AGUtil.h"

@implementation AGSigningKey {
    NSMutableData *_secretKey;
    NSMutableData *_publicKey;
}

- (id)init {
    self = [super init];
    
    if (self) {
        NSMutableData *seed = [NSMutableData dataWithLength:crypto_sign_ed25519_SECRETKEYBYTES];
        randombytes([seed mutableBytes], [seed length]);
        
        _publicKey = [NSMutableData dataWithLength:crypto_sign_ed25519_PUBLICKEYBYTES];
        _secretKey = [NSMutableData dataWithLength:crypto_sign_ed25519_SECRETKEYBYTES];
        
        // Generate the keypair
        int status = crypto_sign_ed25519_seed_keypair([_publicKey mutableBytes],
                                                      [_secretKey mutableBytes],
                                                      [seed mutableBytes]);
        // should not happen
        NSAssert(status == 0, @"Failed to generate a key pair", status);
    }
    
    return self;
}

- (NSData *)sign:(NSData *)message {
    NSParameterAssert(message != nil);
    
    NSMutableData *signature = [AGUtil prependZeros:crypto_sign_ed25519_BYTES msg:message];
   
    unsigned long long bufferLen;
    // sign the message
    int status = crypto_sign_ed25519([signature mutableBytes], &bufferLen,
                                     [message bytes],
                                     [message length],
                                     [_secretKey bytes]);
    
    NSAssert(status == 0, @"unable to sign message", status);
    
    return [signature subdataWithRange:NSMakeRange(0, crypto_sign_ed25519_BYTES)];
}

@end