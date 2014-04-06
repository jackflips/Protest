//
//  ViewController.m
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ViewController.h"
#import "AGSigningKey.h"
#import "AGVerifyKey.h"
#import "MCManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)startProtest:(id)sender {
    NSData *message = [@"My bonnie lies over the ocean" dataUsingEncoding:NSUTF8StringEncoding];
    
    AGSigningKey *signingKey = [[AGSigningKey alloc] init];
    AGVerifyKey *verifyKey = [[AGVerifyKey alloc] initWithKey:signingKey.publicKey];
    // sign the message
    NSData *signedMessage = [signingKey sign:message];
    
    // should detect corrupted signature
    NSMutableData *corruptedSignature = [NSMutableData dataWithLength:64];
    BOOL isValid = [verifyKey verify:message signature:signedMessage];
    
    // isValid should be YES
    isValid = [verifyKey verify:message signature:corruptedSignature];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [_appDelegate.manager setPublicKey:signingKey.publicKey];
    [_appDelegate.manager connect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
