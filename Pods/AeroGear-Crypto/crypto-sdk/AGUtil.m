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

#import "AGUtil.h"

NSString * const AGCryptoErrorDomain = @"AGCryptoErrorDomain";

@implementation AGUtil

+ (NSMutableData *)prependZeros:(NSUInteger)n msg:(NSData *)message {
    NSMutableData *data = [NSMutableData dataWithLength:n+message.length];
    
    [data replaceBytesInRange:NSMakeRange(n, message.length) withBytes:[message bytes]];
    
    return data;
}

+ (NSString *)hexString:(NSData *)data {
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([data length] * 2)];
	const unsigned char *dataBuffer = [data bytes];

	for (int i = 0; i < [data length]; ++i) {
        [stringBuffer appendFormat:@"%02X", dataBuffer[i]];
	}
	return stringBuffer;
}

+ (NSData *)hexStringToBytes:(NSString *)hex {
    NSMutableData *buffer = [NSMutableData data];
    unsigned int intValue;

    for (int i = 0; i + 2 <= [hex length]; i += 2) {
        NSRange range = NSMakeRange(i, 2);
        NSString * hexString = [hex substringWithRange:range];
        NSScanner * scanner = [NSScanner scannerWithString:hexString];
        [scanner scanHexInt:&intValue];
        [buffer appendBytes:&intValue length:1];
    }
    return buffer;
}

@end