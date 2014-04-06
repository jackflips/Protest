//
//  ViewController.m
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ViewController.h"
#import "AeroGearCrypto.h"
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
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.key = [[AGSigningKey alloc] init];
    AGVerifyKey *verifyKey = [[AGVerifyKey alloc] initWithKey:_appDelegate.key.publicKey];
    // sign the message
    NSData *signedMessage = [_appDelegate.key sign:message];
    
    BOOL isValid = [verifyKey verify:message signature:signedMessage];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.manager.leader = YES;
    [_appDelegate.manager setPublicKey:_appDelegate.key.publicKey];
    [_appDelegate.manager connect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
