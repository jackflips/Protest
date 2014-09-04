#import <Foundation/Foundation.h>

@interface XRSA : NSObject {
    SecKeyRef publicKey;
    SecCertificateRef certificate;
    SecPolicyRef policy;
    SecTrustRef trust;
    size_t maxPlainLen;
}
- (XRSA *)initWithData:(NSData *)keyData;
- (XRSA *)initWithPublicKey:(NSString *)publicKeyPath;

- (NSData *) encryptWithData:(NSData *)content;
- (NSData *) encryptWithString:(NSString *)content;
- (NSString *) encryptToString:(NSString *)content;

@end
