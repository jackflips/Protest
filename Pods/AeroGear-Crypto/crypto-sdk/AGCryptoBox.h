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

#import <Foundation/Foundation.h>
#import <libsodium-ios/sodium/crypto_box_curve25519xsalsa20poly1305.h>
#import "AGKeyPair.h"

/**
 * Provide public key authenticated encryption via curve25519xsalsa20poly1305
 * (see http://nacl.cr.yp.to/box.html)
 */
@interface AGCryptoBox : NSObject

@property(readonly, nonatomic, strong) NSData *privateKey;
@property(readonly, nonatomic, strong) NSData *publicKey;

/**
 * Crypto box default initialization
 *
 * @param keyPair containig public and private keys provided.
 *
 * @return the AGCryptoBox object.
 */
- (id)initWithKeyPair:(AGKeyPair *)keyPair;

/**
 * Crypto box initialization
 *
 * @param publicKey the public encryption key provided.
 * @param privateKey the private encryption key provided.
 *
 * @return the AGCryptoBox object.
 */
- (id)initWithKey:(NSData *)publicKey privateKey:(NSData *)privateKey;

/**
 * Encrypts and authenticates the data object provided given a nonce.
 *
 * @param data The data object to encrypt.
 * @param nonce the cryptographically secure pseudorandom number.
 * @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 *
 * @return An NSData object that holds the encrypted(cipher) data.
 */
- (NSData *)encrypt:(NSData *)data nonce:(NSData *)nonce error:(NSError * __autoreleasing *)error;

/**
 * Decrypts the data object provided given a nonce.
 *
 * @param data The data object(cipher) to decrypt.
 * @param nonce The cryptographically secure pseudorandom number.
 * @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 *
 * @return An NSData object that holds the decrypted data.
 */
- (NSData *)decrypt:(NSData *)data nonce:(NSData *)nonce error:(NSError * __autoreleasing *)error;

@end