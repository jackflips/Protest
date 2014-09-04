
#import "Steganographer.h"

@interface Steganographer ()

@end

@implementation Steganographer

+ (instancetype)sharedProcessor {
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - Public

- (void)embedMessage:(UIImage*)inputImage message:(NSString*)message{
    UIImage * outputImage = [self processUsingPixels:inputImage message:message];
    
    if ([self.delegate respondsToSelector:
         @selector(imageProcessorFinishedProcessingWithImage:)]) {
        [self.delegate imageProcessorFinishedProcessingWithImage:outputImage];
    }
}

#pragma mark - Private

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

void decodeByteIntoBools(char theByte, int *bitString, int index) {
    for (int i=0; i<8; i++) {
        bitString[i+index] = ((theByte & (1<<i)) != 0);
    }
}

char getByteFromBools(const bool eightBools[8]) {
    char ret = 0;
    for (int i=0; i<8; i++) if (eightBools[i] == true) ret |= (1<<i);
    return ret;
}

- (NSString*)decodeMessage:(UIImage*)inputImage {
    UInt32 *inputPixels;
    
    CGImageRef inputCGImage = [inputImage CGImage];
    NSUInteger inputWidth = CGImageGetWidth(inputCGImage);
    NSUInteger inputHeight = CGImageGetHeight(inputCGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth;
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), inputCGImage);
    
    char lastChar = 'a';
    NSMutableArray *bits = [NSMutableArray array];
    NSMutableString *decodedText = [NSMutableString string];
    
    
    
    UInt32 *currentPixel = inputPixels;
    UInt32 color = *currentPixel;
    
    useTwoBits = (BOOL)R(color) & 1;
    NSLog(@"%d", useTwoBits);
    currentPixel = currentPixel + 1;
    color = *currentPixel;
    
    if (useTwoBits) {
        while ((uint8_t)lastChar != 0) {
            uint8_t red = R(color);
            [bits addObject:[NSNumber numberWithInt:(int)((red & 2) != 0)]];
            [bits addObject:[NSNumber numberWithInt:red & 1]];
            uint8_t green = G(color);
            [bits addObject:[NSNumber numberWithInt:(int)((green & 2) != 0)]];
            [bits addObject:[NSNumber numberWithInt:green & 1]];
            uint8_t blue = B(color);
            [bits addObject:[NSNumber numberWithInt:(int)((blue & 2) != 0)]];
            [bits addObject:[NSNumber numberWithInt:blue & 1]];
            currentPixel = currentPixel + 1;
            color = *currentPixel;
            if (bits.count >= 8) {
                NSArray *eight = [bits subarrayWithRange:NSMakeRange(0, 8)];
                [bits removeObjectsInRange:NSMakeRange(0, 8)];
                bool bitArr[8];
                for (int i=0; i<8; i++) {
                    bitArr[i] = [eight[i] integerValue];
                }
                char newChar = getByteFromBools(bitArr);
                [decodedText appendFormat:@"%c", newChar];
                lastChar = newChar;
            }
        }
    } else {
        while ((uint8_t)lastChar != 0) {
            uint8_t red = R(color);
            [bits addObject:[NSNumber numberWithInt:red & 1]];
            uint8_t green = G(color);
            [bits addObject:[NSNumber numberWithInt:green & 1]];
            uint8_t blue = B(color);
            [bits addObject:[NSNumber numberWithInt:blue & 1]];
            currentPixel = currentPixel + 1;
            color = *currentPixel;
            if (bits.count >= 8) {
                NSArray *eight = [bits subarrayWithRange:NSMakeRange(0, 8)];
                [bits removeObjectsInRange:NSMakeRange(0, 8)];
                bool bitArr[8];
                for (int i=0; i<8; i++) {
                    bitArr[i] = [eight[i] integerValue];
                }
                char newChar = getByteFromBools(bitArr);
                [decodedText appendFormat:@"%c", newChar];
                lastChar = newChar;
            }
        }
    }
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(inputPixels);
    return decodedText;
}

- (UIImage *)processUsingPixels:(UIImage*)inputImage message:(NSString*)message {
    
    // 1. Get the raw pixels of the image
    UInt32 * inputPixels;
    
    CGImageRef inputCGImage = [inputImage CGImage];
    NSUInteger inputWidth = CGImageGetWidth(inputCGImage);
    NSUInteger inputHeight = CGImageGetHeight(inputCGImage);
    
    if (message.length > (inputHeight * inputWidth) * 6) {
        NSLog(@"Message too long for image");
        return nil;
    } else if (message.length > (inputWidth * inputHeight) * 3) {
        useTwoBits = YES;
    } else {
        useTwoBits = NO;
    }
    
    //useTwoBits = YES;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bitsPerComponent = 8;
    
    NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth;
    
    inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                                 bitsPerComponent, inputBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), inputCGImage);
    
    int index = 0;
    int *bits = calloc(8 * strlen([message UTF8String]) + 9, sizeof(int));
    const char *msg = [message UTF8String];
    for (int i=0; i<strlen(msg); i++) {
        decodeByteIntoBools(msg[i], bits, index);
        index += 8;
    }
    for (int i=0; i<8; i++) {
        bits[index + i] = 0;
        index++;
    }
    bits[index+1] = 2;
    bits[index+2] = 2;
    bits[index+3] = 2;
    UInt32 *currentPixel = inputPixels;
    UInt32 color = *currentPixel;
    
    int bitIndex = 0;
    
    uint8_t red = R(color);
    red = (red & ~1) | useTwoBits;
    *currentPixel = RGBAMake(red, G(color), B(color), A(color));
    currentPixel = currentPixel + 1;
    color = *currentPixel;
    
    if (!useTwoBits) {
        while (bits[bitIndex] != 2) {
            uint8_t red = 0;
            uint8_t blue = 0;
            uint8_t green = 0;
            if (bits[bitIndex] == 2) break;
            red = R(color);
            red = (red & ~1) | bits[bitIndex];
            if (bits[bitIndex+1] == 2) break;
            green = G(color);
            green = (green & ~1) | bits[bitIndex+1];
            if (bits[bitIndex+2] == 2) break;
            blue = B(color);
            blue = (blue & ~1) | bits[bitIndex+2];
            *currentPixel = RGBAMake(red, green, blue, A(color));
            currentPixel = currentPixel + 1;
            color = *currentPixel;
            bitIndex += 3;
        }
    } else {
        while (bits[bitIndex] != 2) {
            uint8_t red = 0;
            uint8_t blue = 0;
            uint8_t green = 0;
            if (bits[bitIndex] == 2) break;
            red = R(color);
            red = (red & ~3) | (bits[bitIndex]*2 + bits[bitIndex+1]);
            if (bits[bitIndex+2] == 2) break;
            green = G(color);
            green = (green & ~3) | (bits[bitIndex+2]*2 + bits[bitIndex+3]);
            if (bits[bitIndex+4] == 2) break;
            blue = B(color);
            blue = (blue & ~3) | (bits[bitIndex+4]*2 + bits[bitIndex+5]);
            *currentPixel = RGBAMake(red, green, blue, A(color));
            currentPixel = currentPixel + 1;
            color = *currentPixel;
            bitIndex += 6;
        }
    }
    
    
    // 4. Create a new UIImage
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
    
    // 5. Cleanup!
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(inputPixels);
    free(bits);

    return processedImage;
}

#undef RGBAMake
#undef R
#undef G
#undef B
#undef A
#undef Mask8

#pragma mark Helpers


@end
