//
//  ViewController.m
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import "ProtestViewController.h"
#import "ConnectionManager.h"
#import "ProtestConfigViewController.h"
#import "ChatViewController.h"

@interface ProtestViewController ()

@property (nonatomic, retain) ProtestConfigViewController *configController;
@property (nonatomic, retain) ChatViewController *chatViewController;

@end

@interface Protest : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic) BOOL passwordNeeded;
@property (nonatomic) int health;
@property (nonatomic) BOOL refreshed;
@property (nonatomic) int numberOfPeers; //this means only immediate peers

@end

@implementation Protest

- (id)initWithName:(NSString*)name passwordNeeded:(BOOL)passwordNeeded andHealth:(int)health {
    self = [super init];
    _name = name;
    _passwordNeeded = passwordNeeded;
    _health = health;
    _refreshed = YES;
    return self;
}

@end

@implementation ProtestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [[ConnectionManager shared] searchForProtests];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startChat:)
                                                 name:@"startChat"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeProtestFromList:)
                                                 name:@"removeProtestFromList"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addProtestToList:)
                                                 name:@"addProtestToList"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startChat:)
                                                 name:@"startChat"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reset:)
                                                 name:@"viewControllerReset"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissConfig:)
                                                 name:@"dismissConfig"
                                               object:nil];
}


- (void)updateProtestHealth {
    if (tableSource.count > 0) {
        [tableSource sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            Protest *d1 = obj1, *d2 = obj2;
            if (d1.numberOfPeers > d2.numberOfPeers) return NSOrderedDescending;
            else if (d1.numberOfPeers == d2.numberOfPeers) return NSOrderedSame;
            else return NSOrderedAscending;
        }];
        int topProtest = [[tableSource objectAtIndex:0] numberOfPeers];
        for (Protest *prot in tableSource) {
            if (prot.numberOfPeers >= topProtest/2) {
                prot.health = 1;
            } else {
                prot.health = 0;
            }
        }
        
    }
}

- (int)tablesourceContainsProtest:(NSString*)protestName {
    for (Protest *protest in tableSource) {
        if ([protest.name isEqualToString:protestName]) {
            return (int)[tableSource indexOfObject:protest];
        }
    }
    return -1;
}

- (void)reset:(NSNotification*)note {
    [tableSource removeAllObjects];
    [_tableView reloadData];
    
    [[ConnectionManager shared] disconnectFromPeers];
    [[ConnectionManager shared] resetState];
    [[ConnectionManager shared] searchForProtests];
    
    [_chatViewController dismissViewControllerAnimated:YES completion:nil];
    _chatViewController = nil;
    _startProtestButton.frame = CGRectMake(0, ([tableSource count] * 55) + 94, 320, 46);
}

- (void)addProtestToList:(NSNotification*)note {
    NSString *nameOfProtest = [[note userInfo] valueForKey:@"protestName"];
    NSString *password = [[note userInfo] valueForKey:@"protestHasPassword"];
    int health = [[[note userInfo] valueForKey:@"protestHealth"] boolValue];
    int indexOfProtest = [self tablesourceContainsProtest:nameOfProtest];
    if (indexOfProtest != -1) { //if the protest is already in the list
        Protest *prot = [tableSource objectAtIndex:indexOfProtest];
        prot.numberOfPeers += 1;
    } else {
        Protest *protest = [[Protest alloc] initWithName:nameOfProtest passwordNeeded:password andHealth:health];
        protest.numberOfPeers += 1;
        [tableSource addObject:protest];
    }
    [self updateProtestHealth];
    [_tableView reloadData];
}

- (void)dismissConfig:(NSNotification*)note {
    [_configController dismissViewControllerAnimated:YES completion:nil];
    _configController = nil;
}

- (void)removeProtestFromList:(NSNotification*)note {
    NSString *name = [[note userInfo] valueForKey:@"protestName"];
    for (int i=0; i<tableSource.count; i++) {
        if ([[[tableSource objectAtIndex:i] name] isEqualToString:name]) {
            Protest *protest = [tableSource objectAtIndex:i];
            protest.numberOfPeers -= 1;
            if (protest.numberOfPeers <= 0) {
                [tableSource removeObjectAtIndex:i];
            }
        }
    }
    [self updateProtestHealth];
    [_tableView reloadData];
}

- (void)startChat:(NSNotification*)note
{
    NSString *name = [[note userInfo] valueForKey:@"protestName"];
    if (!_chatViewController) {
        _chatViewController = [[ChatViewController alloc] init];
    }
    
    [_configController dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:_chatViewController animated:YES completion:^{
            [_chatViewController chatLoaded:name];
        }];
    }];
    
    //NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:name, @"protestName", nil];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"chatLoaded" object:self userInfo:info];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableSource count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    Protest *selectedProtest = [tableSource objectAtIndex:indexPath.row];
    if (selectedProtest.passwordNeeded) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Password" message:@"Enter your password:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
        alertView.tag = indexPath.row;
        [alertView show];
    } else {
        [self joinProtest:selectedProtest.name password:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
    //make call to network - will return success or failiure.
    NSIndexPath *path = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:path];
    [self joinProtest:cell.textLabel.text password:passwordTextField.text];
}

- (void)joinProtest:(NSString*)nameOfProtest password:(NSString*)password
{
    _chatViewController = [[ChatViewController alloc] init];
    
    [self presentViewController:_chatViewController animated:YES completion:nil];
    
    [[ConnectionManager shared] joinProtest:nameOfProtest password:password];
}

- (void)startProtest {
    if (!_configController) {
        _configController = [[ProtestConfigViewController alloc] init];
    } else {
        [_configController reset];
    }
    [_configController dismissViewControllerAnimated:YES completion:nil];
    [self presentViewController:_configController
                                                 animated:YES
                                               completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
