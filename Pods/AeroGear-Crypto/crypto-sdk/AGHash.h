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

/**
 * Class that create a message digest using SHA2 hash function
 * (see http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf)
 */
@interface AGHash : NSObject

/**
 * Initialize with the Hash function provided.
 *
 * @param algorithm The length of hash function e.g. CC_SHA512_DIGEST_LENGTH or CC_SHA256_DIGEST_LENGTH
 *
 * @return The AGHash object.
 */
- (id)init:(char)algorithm;

/**
 * Create a message digest based on the string provided.
 *
 * @param str The raw text.
 *
 * @return an NSData object containing the message digest.
 */
- (NSData *)digest:(NSString *)str;
@end