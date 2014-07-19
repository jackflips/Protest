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

#import "CryptoManager.h"

@interface CryptoManager ()

@property (readwrite, assign) SecKeyRef publicKey;
@property (readwrite, assign) SecKeyRef privateKey;

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

@implementation CryptoManager

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self generate];
    }
    _AESEncyptor = [[RNEncryptor alloc] init];
    _AESDecryptor = [[RNDecryptor alloc] init];
    
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

- (NSData *)sign:(NSData *)plainText withKey:(SecKeyRef)key
{
    size_t blockSizeIncludingPadding = SecKeyGetBlockSize(key);
    size_t blockSize = blockSizeIncludingPadding - 11;
    uint8_t *buffer = calloc(blockSizeIncludingPadding, sizeof(uint8_t));
    
    //    NSLog(@"Encrypting %lu blocks", ([plainText length] + blockSize) / blockSize);
    
    NSMutableData *cipherText = [NSMutableData new];
    for (NSUInteger i = 0; i < [plainText length]; i += blockSize) {
        NSData *subPlainText = [plainText subdataWithRange:NSMakeRange(i, MIN(blockSize, [plainText length] - i))];
        size_t cipherTextLength = blockSizeIncludingPadding;
        OSStatus status = SecKeyRawSign(key, kSecPaddingPKCS1, [subPlainText bytes], [subPlainText length], buffer, &cipherTextLength);
        [cipherText appendBytes:buffer length:cipherTextLength];
    }
    free(buffer);
    return cipherText;
}

- (OSStatus)verify:(NSData *)plainText withSignature:(NSData *)sig andKey:(SecKeyRef)key
{
    OSStatus status = SecKeyRawVerify(key, kSecPaddingPKCS1, [plainText bytes], [plainText length], [sig bytes], [sig length]);
    return status;
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

- (NSData*)getPublicKeyBitsFromKey:(SecKeyRef)givenKey {
    
    static const uint8_t publicKeyIdentifier[] = "com.your.company.publickey";
    NSData *publicTag = [[NSData alloc] initWithBytes:publicKeyIdentifier length:sizeof(publicKeyIdentifier)];
    
    OSStatus sanityCheck = noErr;
    NSData * publicKeyBits = nil;
    
    NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Temporarily add key to the Keychain, return as data:
    NSMutableDictionary * attributes = [queryPublicKey mutableCopy];
    [attributes setObject:(__bridge id)givenKey forKey:(__bridge id)kSecValueRef];
    [attributes setObject:@YES forKey:(__bridge id)kSecReturnData];
    CFTypeRef result;
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) attributes, &result);
    if (sanityCheck == errSecSuccess) {
        publicKeyBits = CFBridgingRelease(result);
        
        // Remove from Keychain again:
        (void)SecItemDelete((__bridge CFDictionaryRef) queryPublicKey);
    }
    
    return publicKeyBits;
}

- (void)removePeerPublicKey:(NSString *)peerName {
	OSStatus sanityCheck = noErr;
	NSData * peerTag = [[NSData alloc] initWithBytes:(const void *)[peerName UTF8String] length:[peerName length]];
	NSMutableDictionary * peerPublicKeyAttr = [[NSMutableDictionary alloc] init];
    
	[peerPublicKeyAttr setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
	[peerPublicKeyAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	[peerPublicKeyAttr setObject:peerTag forKey:(__bridge id)kSecAttrApplicationTag];
    
	sanityCheck = SecItemDelete((__bridge CFDictionaryRef) peerPublicKeyAttr);
}

- (SecKeyRef)addPublicKey:(NSData *)d_key withTag:(NSString *)tag
{
    [self removePeerPublicKey:tag];
    if (d_key == nil) return(FALSE);
    
    NSData *d_tag = [tag dataUsingEncoding:NSUTF8StringEncoding];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    CFTypeRef persistKey = nil;
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:d_key forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    OSStatus secStatus = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) CFRelease(persistKey);
    
    if ((secStatus != noErr) && (secStatus != errSecDuplicateItem)) {
        return(FALSE);
    }
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    
    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef
     ];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    secStatus = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey,
                                    (CFTypeRef *)&keyRef);
    
    if (keyRef == nil) return(FALSE);
    
    return keyRef;
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
