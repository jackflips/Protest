//
//  InternetManager.m
//  Protest
//
//  Created by John Rogers on 9/2/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "InternetManager.h"

@implementation InternetManager

- (void)imageProcessorFinishedProcessingWithImage:(UIImage *)outputImage {
    NSLog(@"%@",[[Steganographer sharedProcessor] decodeMessage:outputImage]);
    
    /*NSData *imgData = UIImagePNGRepresentation(outputImage);
     NSURLResponse *response;
     NSError *error = nil;
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost"]
     cachePolicy:NSURLRequestUseProtocolCachePolicy
     timeoutInterval:60.0];
     
     [request setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
     [request addValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20100101 Firefox/31.0" forHTTPHeaderField:@"User-Agent"];
     [request setHTTPMethod:@"POST"];
     [request setHTTPBody:imgData];
     
     NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
     returningResponse:&response
     error:&error];
     NSLog(@"%@", response);
     NSLog(@"%@", request);
     NSLog(@"%@", receivedData);
     */
}

- (id)init {
    if (self = [super init]) {
        UIImage *image = [UIImage imageNamed:@"rjf_rooster.jpg"];
        //[Steganographer sharedProcessor].delegate = self;
        [[Steganographer sharedProcessor] embedMessage:image message:@"I love Terry Grs."];
    }
    return self;
}

@end
