

#import <Foundation/Foundation.h>

@protocol SteganographerDelegate <NSObject>

- (void)imageProcessorFinishedProcessingWithImage:(UIImage*)outputImage;

@end

@interface Steganographer : NSObject {
    BOOL useTwoBits;
}

@property (weak, nonatomic) id<SteganographerDelegate> delegate;

+ (instancetype)sharedProcessor;

- (void)embedMessage:(UIImage*)inputImage message:(NSString*)message;
- (NSString*)decodeMessage:(UIImage*)inputImage;

@end
