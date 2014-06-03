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

@interface Protest : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic) BOOL passwordNeeded;
@property (nonatomic) int health;

@end

@implementation Protest

- (id)initWithName:(NSString*)name passwordNeeded:(BOOL)passwordNeeded andHealth:(int)health {
    self = [super init];
    _name = name;
    _passwordNeeded = passwordNeeded;
    _health = health;
    return self;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _protests = [NSMutableArray array];
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _appDelegate.manager = [[MCManager alloc] init];
    [_appDelegate.manager searchForProtests];

    _appDelegate.viewController = self;
    tableSource = [NSMutableArray array];
    Protest *sampleProt = [[Protest alloc] initWithName:@"Tahrir Square Allstars" passwordNeeded:YES andHealth:1];
    [tableSource addObject:sampleProt];
    //other sample protest names: @"John/Yoko Bed-in", @"Prague Spring Breakers"
    
    _startProtestButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _startProtestButton.titleLabel.text = @"";
    _startProtestButton.frame = CGRectMake(0, ([tableSource count] * 55) + 94, 320, 46);
    [_startProtestButton addTarget:self action:@selector(startProtest) forControlEvents:UIControlEventTouchUpInside];
    [_startProtestButton setBackgroundImage:[UIImage imageNamed:@"addbutton.png"]
                      forState:UIControlStateNormal];
    [self.view addSubview:_startProtestButton];
    self.view.backgroundColor = [UIColor colorWithRed:0.945 green:0.941 blue:0.918 alpha:1];
}

-(void)buttonPressed:(id)sender {
    NSLog(@"do nothing");
}

- (void)buttonAction:(id)sender {
    NSLog(@"uh");
}

- (void)addProtestToList:(NSString*)nameOfProtest password:(BOOL)password health:(int)health {
    Protest *protest = [[Protest alloc] initWithName:nameOfProtest passwordNeeded:password andHealth:health];
    for (Protest *prot in tableSource) {
        if ([prot.name isEqualToString:nameOfProtest]) {
            [tableSource removeObject:prot];
        }
    }
    [tableSource addObject:protest];
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
    
    //boilerplate tableview setup
    static NSString *simpleTableIdentifier = @"ProtestCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    cell.backgroundView = [[UIImageView alloc] initWithImage:[ [UIImage imageNamed:@"rowimage.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
    cell.selectedBackgroundView =  [[UIImageView alloc] initWithImage:[ [UIImage imageNamed:@"rowimage.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ];
    
    Protest *thisProtest = [tableSource objectAtIndex:indexPath.row];
    cell.textLabel.text = thisProtest.name;
    NSString *cellAccessoryViewImage;
    if (thisProtest.health == 1) {
        if (thisProtest.passwordNeeded) {
            cellAccessoryViewImage = @"greendotlocked.png";
        } else {
            cellAccessoryViewImage = @"greendot.png";
        }
    } else {
        if (thisProtest.passwordNeeded) {
            cellAccessoryViewImage = @"yellowdotlocked.png";
        } else {
            cellAccessoryViewImage = @"yellowdotlocked.png";
        }
    }
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:cellAccessoryViewImage]];
    cell.textLabel.font = [UIFont fontWithName:@"Futura Std" size:21];
    cell.textLabel.textColor = [UIColor colorWithRed:0.349 green:0.349 blue:0.349 alpha:1];
    _startProtestButton.frame = CGRectMake(0, ([tableSource count] * 55) + 94, 320, 46);
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
