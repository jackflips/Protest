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

typedef NS_ENUM(NSInteger, AGCryptoErrorCodes) {
    AGCryptoFailedToEncryptError = -101,
    AGCryptoFailedToDecryptError = -102
};

extern NSString * const AGCryptoErrorDomain;

/**
 * Utility class for cryptographic operations
 */
@interface AGUtil : NSObject

/**
 * Append zeros to the message provided.
 *
 * @param n Number of zeros.
 * @param message The provided message.
 *
 * @return An NSData object that holds the result.
 */
+ (NSMutableData *)prependZeros:(NSUInteger)n msg:(NSData *)message;

/**
 * Convert the provided data to hex.
 *
 * @param data The NSData to be converted to hex representation.
 *
 * @return An NSString object with the result of the conversion.
 */
+ (NSString *)hexString:(NSData *)data;

/**
 * Convert the provided hex string to bytes.
 *
 * @param data The hex string to be converted.
 *
 * @return An NSData object with the result of the conversion.
 */
+ (NSData *)hexStringToBytes:(NSString *)data;

@end