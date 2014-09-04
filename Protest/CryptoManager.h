// Copyright (c) 2014, William LaFrance.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//   * Neither the name of the copyright holder nor the
//     names of its contributors may be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDER BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "RNEncryptor.h"
#import "RNDecryptor.h"

@interface CryptoManager : NSObject {
    RNEncryptor *AESEncryptor;
    RNDecryptor *AESDecryptor;
}

@property (readonly, assign) SecKeyRef publicKey;
@property (readonly, assign) SecKeyRef privateKey;


- (SecKeyRef)addPublicKey:(NSData *)d_key withTag:(NSString *)tag;
- (NSData*)getPublicKeyBitsFromKey:(SecKeyRef)givenKey;

- (NSData *)encrypt:(NSData *)plainText WithPublicKey:(SecKeyRef)publicKey;
- (NSData *)decrypt:(NSData *)cipherText;
- (NSData *)encrypt:(NSData *)plainText password:(NSString *)password;
- (NSData *)decrypt:(NSData *)plainText password:(NSString *)password;
- (NSData *)sign:(NSData *)plainText withKey:(SecKeyRef)key;
- (OSStatus)verify:(NSData *)plainText withSignature:(NSData *)sig andKey:(SecKeyRef)key;
- (NSData *)encryptString:(NSString *)plainText withX509Certificate:(NSData *)certificate;
+ (instancetype)sharedProcessor;


@end
