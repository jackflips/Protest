//
//  ProtestConfigurationViewController.m
//  Protest
//
//  Created by John Rogers on 7/4/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ProtestConfigurationViewController.h"
#import "AppDelegate.h"

@interface ProtestConfigurationViewController ()

@property (nonatomic, retain) AppDelegate *appDelegate;

@end


@implementation ProtestConfigurationViewController

- (IBAction)exitButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)startProtest:(id)sender {
    NSLog(@"starting?");
    _appDelegate.manager.leader = YES;
    [_appDelegate.manager startProtest:_protestNameField.text password:_passwordField.text];
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ChatViewController *chatViewController = (ChatViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
    _appDelegate.chatViewController = chatViewController;
    [self presentViewController:chatViewController animated:YES completion:^{
        [chatViewController chatLoaded:_protestNameField.text];
    }];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"view did load");
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _startButton.enabled = NO;
    [_startButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_protestNameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)textFieldDidChange:(UITextField *)theTextField{
    if ([theTextField.text length] > 0) {
        [_startButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [_startButton setEnabled:YES];
    } else {
        [_startButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_startButton setEnabled:NO];
    }
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
