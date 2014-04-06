# aerogear-crypto-ios [![Build Status](https://travis-ci.org/aerogear/aerogear-crypto-ios.png)](https://travis-ci.org/aerogear/aerogear-crypto-ios)

## Project Aim
_"Crypto for Humans"_

The aim of the project is to provide useful and easy to use API interfaces for performing advanced cryptographic techniques in the iOS platform. Anyone who has tried to use the underlying crypto functionality APIs provided by the iOS, or to integrate with external crypto libraries like OpenSSL, can understand how frustrated the experience can be. The reasons for this are twofold. Firstly, all crypto libraries offer a variety of cryptographic primitives and you need to make a lot of decisions about which specific pieces to use. And if your decisions are wrong, the end-result will be an insecure system. Secondly, most libraries are written using the C language (and for a good reason), but this results in cumbersome usage for an obj-c developer (with potentially adverse and dangerous consequences for the unfamiliar). 

By leveraging the state-of-the-art [NaCl](http://nacl.cr.yp.to) encryption library, which provides extremely powerful cryptographic primitives so the developer doesn't need to worry on choosing the "right" one and offering an easy-to-use interfaces around the platform's build-in Security and CommonCrypto services, we believe Crypto can be transformed from a frustrating experience to an enjoyable one.

We understand that applying good cryptographic techniques is not an easy task and requires deep knowledge of the underlying concepts. But we strongly believe a "friendlier" developer interface can ease that pain.

The project shares the same vision with our sibling AeroGear project [AeroGear-Crypto-Java](https://github.com/aerogear/aerogear-crypto-java). If you are a Java developer, we strongly recommend to look at the project. 

The project is also the base for providing cryptographic services to [AeroGear-IOS](http://www.aerogear.org) library project.

## Requirements

* iOS 7 or higher

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which eases the pain of installing third-party libraries in your programs. The project is already published in the Cocoapods repository, so just add the following line in your _'Podfile'_ :

#### Podfile

```
pod "AeroGear-Crypto", '0.2.3'
```

## Project Status
The following services are currently provided:

* A [Symmetric encryption](http://nacl.cr.yp.to/secretbox.html) interface
* An [Asymmetric encryption interface](http://nacl.cr.yp.to/box.html)
* Password based key generation using [PBKDF2](http://en.wikipedia.org/wiki/PBKDF2)
* Generation of Cryptographically secure [random numbers](http://en.wikipedia.org/wiki/Cryptographically_secure_pseudorandom_number_generator).
* [Digital signatures](http://ed25519.cr.yp.to) support interface 
* [Hashing functions](http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf) interface

## Getting started

### Password based key derivation

    AGPBKDF2 *pbkdf2 = [[AGPBKDF2 alloc] init];
    NSData *rawKey = [pbkdf2 deriveKey:@"passphrase"];

### Symmetric encryption

    //Generate the key
    AGPBKDF2 *pbkdf2 = [[AGPBKDF2 alloc] init];
    NSData *privateKey = [pbkdf2 deriveKey:@"passphrase"];

    //Initializes the secret box
    AGSecretBox *secretBox = [[AGSecretBox alloc] initWithKey:privateKey];

    //Encryption
    NSData *nonce = [AGRandomGenerator randomBytes:32];
    NSData *dataToEncrypt = [@"My bonnie lies over the ocean" dataUsingEncoding:NSUTF8StringEncoding];

    NSData *cipherData = [secretBox encrypt:dataToEncrypt nonce:nonce];

    //Decryption
    AGSecretBox *pandora = [[AGSecretBox alloc] initWithKey:privateKey];
    NSData *message = [secretBox decrypt:cipherData nonce:nonce];

### Asymmetric encryption

    //Create a new key pair
    AGKeyPair *keyPairBob = [[AGKeyPair alloc] init];
    AGKeyPair *keyPairAlice = [[AGKeyPair alloc] init];

    //Initializes the crypto box
    AGCryptoBox *cryptoBox = [[AGCryptoBox alloc] initWithKey:keyPairAlice.publicKey privateKey:keyPairBob.privateKey];

    NSData *nonce = [AGRandomGenerator randomBytes:32];
    NSData *dataToEncrypt = [@"My bonnie lies over the ocean" dataUsingEncoding:NSUTF8StringEncoding];

    NSData *cipherData = [cryptoBox encrypt:dataToEncrypt nonce:nonce];

    //Create a new box to test end to end asymmetric encryption
    AGCryptoBox *pandora = [[AGCryptoBox alloc] initWithKey:keyPairBob.publicKey privateKey:keyPairAlice.privateKey];

    NSData *message = [pandora decrypt:cipherData nonce:nonce];

### Hashing functions

    // create an SHA256 hash
    AGHash *agHash = [[AGHash alloc] init:CC_SHA256_DIGEST_LENGTH];
    NSData *rawPassword = [agHash digest:@"My bonnie lies over the ocean"];

    // create an SHA512 hash
    AGHash *agHash = [[AGHash alloc] init:CC_SHA512_DIGEST_LENGTH];
    NSData *rawPassword = [agHash digest:@"My bonnie lies over the ocean"];

### Digital Signatures

    NSData *message = [@"My bonnie lies over the ocean" dataUsingEncoding:NSUTF8StringEncoding];
    
    AGSigningKey *signingKey = [[AGSigningKey alloc] init];
    AGVerifyKey *verifyKey = [[AGVerifyKey alloc] initWithKey:signingKey.publicKey];
    // sign the message
    NSData *signedMessage = [signingKey sign:message];

    // should detect corrupted signature
    NSMutableData *corruptedSignature = [NSMutableData dataWithLength:64];
    BOOL isValid = [verifyKey verify:message signature:signedMessage];
   
    // isValid should be YES
    BOOL isValid = [verifyKey verify:message signature:corruptedSignature];
    // isValid should be NO

### Generation of Cryptographically secure Random Numbers
   NSData *random = [AGRandomGenerator randomBytes:<length>];
	

## Join us
On-going work is tracked on project's [JIRA]((https://issues.jboss.org/browse/AGIOS) issue tracker as well as on our [mailing list](https://lists.jboss.org/mailman/listinfo/aerogear-dev). You can also find the developers hanging on [IRC](irc://irc.freenode.net/aerogear), feel free to join in the discussions. We want your feedback!
