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
    tableSource = [NSArray arrayWithObjects:@"TA Strike", @"Murder is Bad", @"Stealing is Bad", nil];
	// Do any additional setup after loading the view, typically from a nib.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [tableSource objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self joinProtest:nil];
    }
}

- (IBAction)joinProtest:(id)sender {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.myKey = [[AGSigningKey alloc] init];
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    FirstViewController *firstViewController = (FirstViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"FirstViewController"];
    _appDelegate.firstViewController = firstViewController;
    [_appDelegate.window.rootViewController presentViewController: firstViewController animated:YES completion:nil];
    [_appDelegate.manager joinProtest];
}

- (IBAction)startProtest:(id)sender {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.myKey = [[AGSigningKey alloc] init];
    _appDelegate.leaderKey = _appDelegate.myKey.publicKey;
    _appDelegate.manager.leader = YES;
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
