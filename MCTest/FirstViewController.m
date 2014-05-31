//
//  FirstViewController.m
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//
//
//  FirstViewController.m
//  MCDemo
//

#import "FirstViewController.h"
#import "AppDelegate.h"

@interface FirstViewController ()

@property (nonatomic, strong) AppDelegate *appDelegate;

-(void)sendMyMessage;
-(void)didReceiveDataWithNotification:(NSNotification *)notification;

@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _txtMessage.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"MCDidReceiveDataNotification"
                                               object:nil];
    
    _chatSource = [NSMutableArray array];
    _availAvatars = [NSMutableArray array];
    for (int i=1; i<=40; i++) {
        [_availAvatars addObject:[NSNumber numberWithInt:i]];
    }
    _avatarForUser = [[NSMutableDictionary alloc] init];
    
}

- (void)protestNameCallback:(NSString*)name {
    _protestName.font = [UIFont fontWithName:@"Gotham" size:18];
    _protestName.textColor = [UIColor whiteColor];
    _protestName.text = name;
}

- (void)addMessage:(Message*)message {
    NSLog(@"recieved message! %@", message);
    if ([_avatarForUser objectForKey:message.uId] == nil) {
        uint32_t rnd = arc4random_uniform([_availAvatars count]);
        NSNumber *avatarNum = [_availAvatars objectAtIndex:rnd];
        [_availAvatars removeObject:avatarNum];
        [_avatarForUser setValue:avatarNum forKey:message.uId];
    }
    [_chatSource addObject:message];
    [_chatTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITextField Delegate method implementation

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self sendMyMessage];
    return YES;
}


#pragma mark - IBAction method implementation

- (IBAction)sendMessage:(id)sender {
    [self sendMyMessage];
}

- (IBAction)cancelMessage:(id)sender {
    [_txtMessage resignFirstResponder];
}

- (IBAction)exitButtonPressed:(id)sender {
    NSLog(@"exit button pressed");
}


#pragma mark - Private method implementation


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_chatSource count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *text = [_chatSource[indexPath.row] message];
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    textLabel.text = text;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:@"Futura Std" size:12], NSFontAttributeName,
                                          nil];
    
    CGRect frame = [textLabel.text boundingRectWithSize:CGSizeMake(220, 2000.0)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:attributesDictionary
                                                context:nil];
    return frame.size.height + 30;
}

- (UITableViewCell*)othersChatBubble:(NSString*)text cell:(UITableViewCell*)cell avatarID:(int)id {
    UIImage *bubbleImage = [[UIImage imageNamed:@"white_text_bubble.png"]
                           resizableImageWithCapInsets:UIEdgeInsetsMake(20, 6, 6, 0)];
    cell.backgroundColor = [UIColor clearColor];
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:bubbleImage];
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    textLabel.font = [UIFont fontWithName:@"Futura Std" size:12];
    textLabel.textColor = [UIColor colorWithRed:0.482 green:0.482 blue:0.482 alpha:1]; /*#7b7b7b*/
    textLabel.text = text;
    
    
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:@"Futura Std" size:12], NSFontAttributeName,
                                          nil];
    
    CGRect frame = [textLabel.text boundingRectWithSize:CGSizeMake(220, 2000.0)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:attributesDictionary
                                                context:nil];
    
    CGSize size = frame.size;
    
    textLabel.frame = CGRectMake(12, 8, size.width, size.height + 5);
    textLabel.numberOfLines = 0;
    [textLabel sizeToFit];
    bubbleImageView.frame = CGRectMake(55, 8, size.width + 20, size.height + 18); //set these variables as you want
    [bubbleImageView addSubview:textLabel];
    
    NSString *iconString = [NSString stringWithFormat:@"%@%i%@", @"icon", id, @".png"];
    NSLog(@"%@", iconString);
    
    UIImage *avatarImage = [UIImage imageNamed:iconString];
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:avatarImage];
    avatarImageView.frame = CGRectMake(12, 8, avatarImage.size.width, avatarImage.size.height);
    textLabel.frame = CGRectMake(12, 4, size.width, size.height + 5);
    [cell.contentView addSubview:avatarImageView];
    [cell.contentView addSubview:bubbleImageView];
    
    return cell;
}

- (UITableViewCell*)selfChatBubble:(NSString*)text cell:(UITableViewCell*)cell {
    UIImage *bubbleImage = [[UIImage imageNamed:@"blue_text_bubble.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 20, 20)];
    cell.backgroundColor = [UIColor clearColor];
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:bubbleImage];
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    textLabel.font = [UIFont fontWithName:@"Futura Std" size:12];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.text = text;
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:@"Futura Std" size:12], NSFontAttributeName,
                                          nil];

    CGRect frame = [textLabel.text boundingRectWithSize:CGSizeMake(220, 2000.0)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:attributesDictionary
                                                context:nil];
    
    CGSize size = frame.size;
    
    textLabel.numberOfLines = 0;
    [textLabel sizeToFit];
    bubbleImageView.frame = CGRectMake(308 - (size.width + 24), 8, size.width + 20, size.height + 18); //set these variables as you want
    [bubbleImageView addSubview:textLabel];
    textLabel.frame = CGRectMake(8, 4, size.width, size.height + 5);
    [cell.contentView addSubview:bubbleImageView];
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    
    Message *message = [_chatSource objectAtIndex:indexPath.row];
    
    [self othersChatBubble:message.message cell:cell avatarID:[[_avatarForUser objectForKey:message.uId] intValue]];

    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[_chatSource addObject:@"Hello! My name is Roger Sabonis and I work for the city. Please stop protesting. People might get mad..."];
    //[tableView reloadData];
}









@end
