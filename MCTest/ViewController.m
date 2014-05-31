//
//  ViewController.m
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ViewController.h"
#import "MCManager.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (nonatomic, retain) AppDelegate *appDelegate;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _protests = [NSMutableArray array];
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    _appDelegate.viewController = self;
    tableSource = [NSMutableArray arrayWithObjects:@"Tahrir Square Allstars", @"John/Yoko Bed-in", @"Prague Spring Breakers", nil];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.text = @"";
    button.frame = CGRectMake(0, ([tableSource count] * 55) + 94, 320, 46);
    [button addTarget:self action:@selector(startProtest) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:@"addbutton.png"]
                      forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    [_appDelegate.manager browseForProtests];
    self.view.backgroundColor = [UIColor colorWithRed:0.945 green:0.941 blue:0.918 alpha:1];
}

-(void)buttonPressed:(id)sender {
    NSLog(@"do nothing");
}

- (void)buttonAction:(id)sender {
    NSLog(@"uh");
}

- (void)addProtestToList:(NSDictionary*)protest {
    [tableSource removeAllObjects];
    [_protests addObject:protest];
    for (NSDictionary *dict in _protests) {
        [tableSource addObject:[dict objectForKey:@"name"]];
    }
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableSource count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [tableSource objectAtIndex:indexPath.row];
    
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ [UIImage imageNamed:@"rowimage.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
    cell.selectedBackgroundView =  [[UIImageView alloc] initWithImage:[ [UIImage imageNamed:@"rowimage.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"greendotlocked.png"]];
    cell.textLabel.font = [UIFont fontWithName:@"Futura Std" size:21];
    cell.textLabel.textColor = [UIColor colorWithRed:0.349 green:0.349 blue:0.349 alpha:1];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password" message:@"Enter your password:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    alertView.tag = indexPath.row;
    [alertView show];
    /*
    NSDictionary* selectedProtest = [_protests objectAtIndex:indexPath.row];
    if ([selectedProtest objectForKey:@"password"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password" message:@"Enter your password:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
        UITextField *passwordTextField = [alertView textFieldAtIndex:0];
        [alertView show];

    }
    [_appDelegate.manager connectToPeer:[selectedProtest objectForKey:@"peerID"] password:[selectedProtest objectForKey:@"password"]];
    */
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
    //make call to network - will return success or failiure.
    NSString *pw = @"hey";
    if ([passwordTextField.text isEqualToString:pw]) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:path];
        [self joinProtest:cell.textLabel.text];
    }
}

- (void)joinProtest:(NSString*)nameOfProtest {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    FirstViewController *firstViewController = (FirstViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"FirstViewController"];
    _appDelegate.firstViewController = firstViewController;
    [_appDelegate.manager joinProtest];
    [_appDelegate.window.rootViewController presentViewController:firstViewController animated:YES completion:^{
        [firstViewController protestNameCallback:nameOfProtest];
    }];
}

- (void)startProtest {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _appDelegate.manager.leader = YES;
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    FirstViewController *firstViewController = (FirstViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"FirstViewController"];
    _appDelegate.firstViewController = firstViewController;
    [_appDelegate.manager startProtest:@"First Protest" password:@"hey"];
    [_appDelegate.window.rootViewController presentViewController:firstViewController animated:YES completion:^{
        [firstViewController protestNameCallback:@"First Protest"];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
