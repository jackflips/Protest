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

#import <CommonCrypto/CommonDigest.h>
#import "AGHash.h"


@implementation AGHash {
    unsigned char _algorithm;
}

- (id)init:(char)algorithm {
    self = [super init];
    if (self) {
        _algorithm = algorithm;
    }

    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _algorithm = CC_SHA256_DIGEST_LENGTH;
    }

    return self;
}

- (NSData *)digest:(NSString *)str {
    NSData *dataIn = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *hash = [NSMutableData dataWithLength:_algorithm];

    if (_algorithm == CC_SHA512_DIGEST_LENGTH ) {
        CC_SHA512(dataIn.bytes, (CC_LONG)dataIn.length, hash.mutableBytes);
    } else {
        CC_SHA256(dataIn.bytes, (CC_LONG)dataIn.length, hash.mutableBytes);
    }

    return hash;
}

@end