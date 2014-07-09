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

#import "RSAManager.h"

@interface RSAManagerContext ()

@property (readwrite, assign) SecKeyRef publicKey;
@property (assign) SecKeyRef privateKey;

@end

const char * __attribute__((pure)) errSecGetNameFromStatus(OSStatus errorCode) {
    switch (errorCode) {
        case errSecSuccess:
            // No error.
            return "errSecSuccess";
            
        case errSecUnimplemented:
            // The function or operation is not implemented.
            return "errSecUnimplemented";
            
        case errSecParam:
            // One or more parameters passed to a function were not valid.
            return "errSecParam";
            
        case errSecAllocate:
            // Failed to allocate memory.
            return "errSecAllocate";
            
        case errSecNotAvailable:
            // No keychain is available.
            return "errSecNotAvailable";
            
        case errSecAuthFailed:
            // Authorization or authentication failed.
            return "errSecAuthFailed";
            
        case errSecDuplicateItem:
            // An item with the same primary key attributes already exists.
            return "errSecDuplicateItem";
            
        case errSecItemNotFound:
            // The item cannot be found.
            return "errSecItemNotFound";
            
        case errSecInteractionNotAllowed:
            // Interaction with the user is required in order to grant access or process a request; however, user
            // interaction with the Security Server has been disabled by the program.
            return "errSecInteractionNotAllowed";
            
        case errSecDecode:
            // Unable to decode the provided data.
            return "errSecDecode";
            
        default:
            return "unknown OSStatus value";
    }
}

@implementation WJLPkcsContext

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self generate];
    }
    
    return self;
}

- (instancetype)initWithPublicKey:(SecKeyRef)publicKey
{
    self = [super init];
    
    if (self) {
        self.publicKey = (SecKeyRef) CFRetain(publicKey);
    }
    
    return self;
}

- (void)generate
{
    NSDictionary *parameters = @{
                                 (__bridge id) kSecAttrKeyType: (__bridge id) kSecAttrKeyTypeRSA,
                                 (__bridge id) kSecAttrKeySizeInBits: @2048
                                 };
    
    SecKeyRef newPublicKey;
    SecKeyRef newPrivateKey;
    
    OSStatus status = SecKeyGeneratePair((__bridge CFDictionaryRef) parameters, &newPublicKey, &newPrivateKey);
    
    NSAssert(errSecSuccess == status, @"Could not generate key. SecKeyGeneratePair returned %s", errSecGetNameFromStatus(status));
    //    NSLog(@"Generated new key pair.");
    
    self.publicKey = newPublicKey;
    self.privateKey = newPrivateKey;
}

- (NSData *)encrypt:(NSData *)plainText WithPublicKey:(SecKeyRef)publicKey
{
    NSAssert(NULL != publicKey, @"Must have public key for recipient in order to encrypt");
    
    size_t blockSizeIncludingPadding = SecKeyGetBlockSize(publicKey);
    size_t blockSize = blockSizeIncludingPadding - 11;
    uint8_t *buffer = calloc(blockSizeIncludingPadding, sizeof(uint8_t));
    
    //    NSLog(@"Encrypting %lu blocks", ([plainText length] + blockSize) / blockSize);
    
    NSMutableData *cipherText = [NSMutableData new];
    for (NSUInteger i = 0; i < [plainText length]; i += blockSize) {
        NSData *subPlainText = [plainText subdataWithRange:NSMakeRange(i, MIN(blockSize, [plainText length] - i))];
        size_t cipherTextLength = blockSizeIncludingPadding;
        
        OSStatus status = SecKeyEncrypt(publicKey, kSecPaddingPKCS1, [subPlainText bytes], [subPlainText length], buffer, &cipherTextLength);
        NSAssert(errSecSuccess == status, @"Could not encrypt. SecKeyEncrypt returned %s", errSecGetNameFromStatus(status));
        
        [cipherText appendBytes:buffer length:cipherTextLength];
    }
    
    free(buffer);
    return cipherText;
}

- (NSData *)decrypt:(NSData *)cipherText
{
    NSAssert(NULL != self.privateKey, @"Must have private key in order to decrypt");
    
    size_t blockSize = SecKeyGetBlockSize(self.privateKey);
    uint8_t *buffer = calloc(blockSize, sizeof(uint8_t));
    
    //    NSLog(@"Decrypting %lu blocks", ([cipherText length] + blockSize) / blockSize);
    
    NSMutableData *plainText = [NSMutableData new];
    for (NSUInteger i = 0; i < [cipherText length]; i += blockSize) {
        NSData *subCipherText = [cipherText subdataWithRange:NSMakeRange(i, MIN(blockSize, [cipherText length] - i))];
        size_t plainTextLen = blockSize;
        
        OSStatus status = SecKeyDecrypt(self.privateKey, kSecPaddingPKCS1, [subCipherText bytes], [subCipherText length], buffer, &plainTextLen);
        NSAssert(errSecSuccess == status, @"Could not decrypt. SecKeyDecrypt returned %s", errSecGetNameFromStatus(status));
        
        [plainText appendBytes:buffer length:plainTextLen];
    }
    
    free(buffer);
    return plainText;
}

- (void)dealloc
{
    if (NULL != self.publicKey) {
        CFRelease(self.publicKey);
        self.publicKey = NULL;
    }
    if (NULL != self.privateKey) {
        CFRelease(self.privateKey);
        self.privateKey = NULL;
    }
}

@end
