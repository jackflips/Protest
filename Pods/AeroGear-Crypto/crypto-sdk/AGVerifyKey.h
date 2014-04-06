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
 * Verify digital signatures
 * (see http://ed25519.cr.yp.to)
 */
@interface AGVerifyKey : NSObject

/**
 * Initialize with the public key provided.
 *
 * @param key The Public key.
 
 * @return the AGVerifyKey object.
 */
- (id)initWithKey:(NSData *)key;

- (id)getKey;

/**
 * Verify the integrity of the message with the signature provided.
 *
 * @param message The message to be verified.
 * @param signature The provided signature.
 *
 * @return the result of the verification process.
 */
- (BOOL)verify:(NSData *)message signature:(NSData *)signature;

@end