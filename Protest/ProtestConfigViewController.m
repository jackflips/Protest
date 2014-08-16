//
//  ProtestConfigurationViewController.m
//  Protest
//
//  Created by John Rogers on 7/4/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ProtestConfigViewController.h"

@implementation ProtestConfigViewController

- (IBAction)exitButtonPressed:(id)sender {
    [_appDelegate.viewController dismissConfig];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)startProtest:(id)sender {
    _appDelegate.manager.leader = YES;
    NSString *password = nil;
    if (_passwordField.text.length > 0) password = _passwordField.text;
    [_appDelegate.manager startProtest:_protestNameField.text password:password];
    [_appDelegate.viewController startChat:_protestNameField.text];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"view did load");
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _startButton.enabled = NO;
    [_startButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_protestNameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)textFieldDidChange:(UITextField *)theTextField{
    if ([theTextField.text length] > 0) {
        [_startButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [_startButton setEnabled:YES];
    } else {
        [_startButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_startButton setEnabled:NO];
    }
}

- (void)reset {
    _passwordField.text = @"";
    _protestNameField.text = @"";
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
