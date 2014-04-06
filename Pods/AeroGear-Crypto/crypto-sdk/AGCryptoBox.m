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

#import "AGCryptoBox.h"
#import "AGUtil.h"

@implementation AGCryptoBox

- (id)initWithKeyPair:(AGKeyPair *)keyPair {
    return [self initWithKey:keyPair.publicKey privateKey:keyPair.privateKey];
}

- (id)initWithKey:(NSData *)publicKey privateKey:(NSData *)privateKey {
    NSParameterAssert(privateKey != nil && [privateKey length] == crypto_box_curve25519xsalsa20poly1305_SECRETKEYBYTES);
    NSParameterAssert(publicKey != nil && [publicKey length] == crypto_box_curve25519xsalsa20poly1305_PUBLICKEYBYTES);
    
    self = [super init];
    
    if (self) {
        _privateKey = privateKey;
        _publicKey = publicKey;
    }
    return self;
}

- (NSData *)encrypt:(NSData *)data nonce:(NSData *)nonce error:(NSError * __autoreleasing *)error {
    NSParameterAssert(data != nil);
    NSParameterAssert(nonce != nil && [nonce length] == crypto_box_curve25519xsalsa20poly1305_NONCEBYTES);

    NSData *msg = [AGUtil prependZeros:crypto_box_curve25519xsalsa20poly1305_ZEROBYTES msg:data];
    NSMutableData *ct = [[NSMutableData alloc] initWithLength:msg.length];

    int status = crypto_box_curve25519xsalsa20poly1305(
                                               [ct mutableBytes],
                                               [msg bytes],
                                               msg.length,
                                               [nonce bytes],
                                               [_publicKey bytes],
                                               [_privateKey bytes]);

    if (status != 0) {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:
                    [NSString stringWithFormat:@"failed to encrypt data provided, NaCl error: %d", status]};
            *error = [NSError errorWithDomain:AGCryptoErrorDomain code:AGCryptoFailedToEncryptError userInfo:userInfo];
        }
        return nil;
    }

    return [ct subdataWithRange:NSMakeRange(crypto_box_curve25519xsalsa20poly1305_BOXZEROBYTES,
                                            ct.length - crypto_box_curve25519xsalsa20poly1305_BOXZEROBYTES)];
}

- (NSData *)decrypt:(NSData *)data nonce:(NSData *)nonce error:(NSError * __autoreleasing *)error {
    NSParameterAssert(data != nil);
    NSParameterAssert(nonce != nil && [nonce length] == crypto_box_curve25519xsalsa20poly1305_NONCEBYTES);
    
    NSData *ct = [AGUtil prependZeros:crypto_box_curve25519xsalsa20poly1305_BOXZEROBYTES msg:data];
    NSMutableData *message = [[NSMutableData alloc] initWithLength:ct.length];

    int status = crypto_box_curve25519xsalsa20poly1305_open(
                                                    [message mutableBytes],
                                                    [ct bytes],
                                                    message.length,
                                                    [nonce bytes],
                                                    [_publicKey bytes],
                                                    [_privateKey bytes]);

    if (status != 0) {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:
                    [NSString stringWithFormat:@"failed to decrypt data provided, NaCl error: %d", status]};
            *error = [NSError errorWithDomain:AGCryptoErrorDomain code:AGCryptoFailedToDecryptError userInfo:userInfo];
        }
        return nil;
    }

    return [message subdataWithRange:NSMakeRange(crypto_box_curve25519xsalsa20poly1305_ZEROBYTES,
                                                 message.length - crypto_box_curve25519xsalsa20poly1305_ZEROBYTES)];
}

@end