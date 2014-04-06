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

#import "AGPBKDF2.h"
#import "AGRandomGenerator.h"

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

const NSUInteger AGPBKDF2Iterations = 20000;
const NSUInteger AGPBKDF2MinimumIterations = 10000;
const NSUInteger AGPBKDF2DerivedKeyLength = 32;
const NSUInteger AGPBKDF2MinimumSaltLength = 16;

@implementation AGPBKDF2 {
    NSData *_salt;
}

- (NSData *)deriveKey:(NSString *)password {
    return [self deriveKey:password salt:[AGRandomGenerator randomBytes]];
}

- (NSData *)deriveKey:(NSString *)password salt:(NSData *)salt {
    return [self deriveKey:password salt:salt iterations:AGPBKDF2Iterations];
}

- (NSData *)deriveKey:(NSString *)password salt:(NSData *)salt iterations:(NSUInteger)iterations {
    NSParameterAssert(password != nil);
    NSParameterAssert(salt != nil && [salt length] >= AGPBKDF2MinimumSaltLength);
    NSParameterAssert(iterations >= AGPBKDF2MinimumIterations);
    
    _salt = salt;
    
    NSMutableData *key = [NSMutableData dataWithLength:AGPBKDF2DerivedKeyLength];
    
    int result = CCKeyDerivationPBKDF(kCCPBKDF2,
                                      [password UTF8String],
                                      [password length],
                                      [salt bytes],
                                      [salt length],
                                      kCCPRFHmacAlgSHA1,
                                      (uint)iterations,
                                      [key mutableBytes],
                                      AGPBKDF2DerivedKeyLength);
    if (result == kCCParamError) {
        return nil;
    }
    
    return key;
}

- (BOOL)validate:(NSString *)password encryptedPassword:(NSData *)encryptedPassword salt:(NSData *)salt {
    NSData *attempt = [self deriveKey:password salt:salt];
    
    return [encryptedPassword isEqual:attempt];    
}

- (NSData *)salt {
    return _salt;
}

@end
