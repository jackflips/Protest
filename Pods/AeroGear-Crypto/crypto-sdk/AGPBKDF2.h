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

// constants used by PBKDF2 algorithm.
extern const NSUInteger AGPBKDF2Iterations;
extern const NSUInteger AGPBKDF2MinimumIterations;
extern const NSUInteger AGPBKDF2DerivedKeyLength;
extern const NSUInteger AGPBKDF2MinimumSaltLength;

/**
 * Class that derives a key from a text password/passphrase using
 * the PBKDF2 algorithm provided by CommonCrypto.
 * (see http://en.wikipedia.org/wiki/PBKDF2)
 */
@interface AGPBKDF2 : NSObject

/**
 * Derive a key from text password/passphrase.
 *
 * @param password The password/passphrase to use for key derivation.
 *
 * @return an NSData object containing the derived key.
 */
- (NSData *)deriveKey:(NSString *)password;

/**
 * Derive a key from text password/passphrase.
 *
 * @param password The password/passphrase to use for key derivation.
 * @param salt A randomly chosen value used used during key derivation.
 *
 * @return an NSData object containing the derived key.
 */
- (NSData *)deriveKey:(NSString *)password salt:(NSData *)salt;

/**
 * Derive a key from text password/passphrase.
 *
 * @param password The password/passphrase to use for key derivation.
 * @param salt A randomly chosen value used used during key derivation.
 * @param iterations The number of iterations against the cryptographic hash.
 *
 * @return an NSData object containing the derived key.
 */
- (NSData *)deriveKey:(NSString *)password salt:(NSData *)salt iterations:(NSUInteger)iterations;

- (BOOL)validate:(NSString *)password encryptedPassword:(NSData *)encryptedPassword salt:(NSData *)salt;

/**
 * Returns the salt used for the key derivation
 *
 * @return an NSData object containing the salt
 */
- (NSData *)salt;

@end
