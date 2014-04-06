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
- (IBAction)joinProtest:(id)sender {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    FirstViewController *firstViewController = (FirstViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"FirstViewController"];
    _appDelegate.firstViewController = firstViewController;
    [_appDelegate.window.rootViewController presentViewController: firstViewController animated:YES completion:nil];
    
    [_appDelegate.manager joinProtest];
}

- (IBAction)startProtest:(id)sender {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.key = [[AGSigningKey alloc] init];
    _appDelegate.manager.leader = YES;
    [_appDelegate.manager setPublicKey:_appDelegate.key.publicKey];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    FirstViewController *firstViewController = (FirstViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"FirstViewController"];
    _appDelegate.firstViewController = firstViewController;
    [_appDelegate.window.rootViewController presentViewController: firstViewController animated:YES completion:nil];
    
    [_appDelegate.manager connect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
