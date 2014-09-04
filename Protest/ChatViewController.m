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

#import "ChatViewController.h"

@interface ChatViewController ()

@end

@implementation ChatViewController

- (void)dismiss
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    _chatSource = [NSMutableArray array];
    _availAvatars = [NSMutableArray array];
    for (int i=1; i<=40; i++) {
        [_availAvatars addObject:[NSNumber numberWithInt:i]];
    }
    _avatarForUser = [[NSMutableDictionary alloc] init];
    _protestName.hidden = YES;
    _chatTable.hidden = YES;
    _protestName.textColor = [UIColor whiteColor];
    _protestName.font = [UIFont fontWithName:@"Gotham" size:18];
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_spinner setColor:[UIColor grayColor]];
    [_spinner setCenter:CGPointMake(160, 240)]; // I do this because I'm in landscape mode
    [self.view addSubview:_spinner]; // spinner is not visible until started
    [_spinner startAnimating];
    
    _warningMessage = [[Message alloc] initWithMessage:@"There's no one else in the chat right now." uID:@"41" fromLeader:NO];
    [_avatarForUser setValue:[NSNumber numberWithInt:41] forKey:_warningMessage.uId];
    
    [self registerForKeyboardNotifications];
    
    _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                           self.view.bounds.size.height - 40.0f,
                                                           self.view.bounds.size.width,
                                                           40.0f)];
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_toolBar];
    
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(10.0f,
                                                               6.0f,
                                                               _toolBar.bounds.size.width - 20.0f - 68.0f,
                                                               30.0f)];
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_toolBar addSubview:_textField];
    
    _sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_sendButton setTitle:@"Send" forState:UIControlStateNormal];
    _sendButton.frame = CGRectMake(_toolBar.bounds.size.width - 68.0f,
                                   6.0f,
                                   58.0f,
                                   29.0f);
    [_sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_sendButton setEnabled:NO];
    [_sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:_sendButton];
    
    
    self.view.keyboardTriggerOffset = _toolBar.bounds.size.height;
    
    __weak ChatViewController *self_ = self; //to avoid retain cycle
    [self.view addKeyboardPanningWithFrameBasedActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        CGRect toolBarFrame = self_.toolBar.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        self_.toolBar.frame = toolBarFrame;
    } constraintBasedActionHandler:nil];
    
    [_textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    /*
    NSIndexPath* ipath = [NSIndexPath indexPathForRow:[_chatTable numberOfRowsInSection:0]-1 inSection:0];
    [_chatTable scrollToRowAtIndexPath:ipath atScrollPosition: UITableViewScrollPositionTop animated:YES];
     */
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatLoadedNotification:)
                                                 name:@"chatLoaded"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessage:)
                                                 name:@"addMessage"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePeerNumber:)
                                                 name:@"updatePeerNumber"
                                               object:nil];
    
}

- (void)updatePeerNumber:(NSNotification*)note {
    int numberOfPeers = (int)[[ConnectionManager shared] sessions].count;
    if (numberOfPeers <= 0) {
        [_sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_sendButton setEnabled:NO];
        [_textField setEnabled:NO];
        [self addNoPeersWarning];
    } else {
        [_sendButton setEnabled:YES];
        [_textField setEnabled:YES];
        if ([_textField.text length] > 0) {
            [_sendButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        }
        [self removeNoPeersWarning];
        //[self updateNumber];
    }
}

- (void)addNoPeersWarning {
    NSLog(@"added warning");
    [_chatSource addObject:_warningMessage];
    [_chatTable reloadData];
    NSIndexPath* ipath = [NSIndexPath indexPathForRow:[_chatTable numberOfRowsInSection:0]-1 inSection:0];
    [_chatTable scrollToRowAtIndexPath:ipath atScrollPosition: UITableViewScrollPositionTop animated:YES];
}

- (void)removeNoPeersWarning {
    [_chatSource removeObject:_warningMessage];
    [_chatTable reloadData];
}

-(void)textFieldDidChange :(UITextField *)theTextField{
    if ([theTextField.text length] > 0) {
        if ([theTextField.text length] > 650) { //need to constrain messages to a certain length to ensure all of the packets will be uniform
            [_sendButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [_sendButton setEnabled:NO];
        } else {
            if ([[ConnectionManager shared] sessions].count > 0) {
                [_sendButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
                [_sendButton setEnabled:YES];
            }
        }
    } else {
        [_sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_sendButton setEnabled:NO];
    }
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    NSDictionary *userInfo = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _chatTable.contentInset = contentInsets;
    _chatTable.scrollIndicatorInsets = contentInsets;
    //NSIndexPath* ipath = [NSIndexPath indexPathForRow:[_chatTable numberOfRowsInSection:0]-1 inSection:0];
    //[_chatTable scrollToRowAtIndexPath:ipath atScrollPosition: UITableViewScrollPositionTop animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _chatTable.contentInset = contentInsets;
    _chatTable .scrollIndicatorInsets = contentInsets;
}

- (void)chatLoadedNotification:(NSNotification*)note {
    NSString *protestName = [[note userInfo] valueForKey:@"protestName"];
    [self chatLoaded:protestName];
}

- (void)addMessage:(Message *)message {
    if ([_avatarForUser objectForKey:message.uId] == nil) {
        uint32_t rnd = arc4random_uniform((uint32_t)_availAvatars.count - 1) + 1; //between 2 and availAvatars.count
        NSNumber *avatarNum = [_availAvatars objectAtIndex:rnd];
        [_availAvatars removeObject:avatarNum];
        [_avatarForUser setValue:avatarNum forKey:message.uId];
    }
    [_chatSource addObject:message];
    [_chatTable reloadData];
    NSIndexPath* ipath = [NSIndexPath indexPathForRow:[_chatTable numberOfRowsInSection:0]-1 inSection:0];
    [_chatTable scrollToRowAtIndexPath:ipath atScrollPosition: UITableViewScrollPositionTop animated:YES];
}

- (void)newMessage:(NSNotification*)note {
    Message *message = [[note userInfo] valueForKey:@"newMessage"];
    [self addMessage:message];
}

- (void)chatLoaded:(NSString*)protestName {
    _protestName.hidden = NO;
    _chatTable.hidden = NO;
    _protestName.text = protestName;
    [_spinner removeFromSuperview];
    [self updatePeerNumber:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showBrowseResults:(id)sender {
    [[ConnectionManager shared] showBrowserResults];
}

#pragma mark - UITextField Delegate method implementation

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    return YES;
}


#pragma mark - IBAction method implementation

- (IBAction)exitButtonPressed:(id)sender {
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"viewControllerReset" object:self userInfo:nil];
    });
}


- (IBAction)sendButtonPressed:(id)sender {
    NSLog(@"send button pressed");
    [_textField resignFirstResponder];
    Message *myMessage = [[Message alloc] initWithMessage:_textField.text uID:[ConnectionManager shared].userID fromLeader:NO];
    myMessage.timer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                       target:self
                                                     selector:@selector(messageNotReturned)
                                                     userInfo:nil
                                                      repeats:NO];
    [_textField setText:@""];
    [_chatSource addObject:myMessage];
    [_chatTable reloadData];
    [[ConnectionManager shared] sendMessage:myMessage];
    [self.view endEditing:YES];
}

- (void)messageNotReturned {
    NSLog(@"Message not returned yet");
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

- (UITableViewCell*)othersChatBubble:(NSString*)text cell:(UITableViewCell*)cell avatarID:(int)id fromLeader:(BOOL)fromLeader {
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
    
    NSString *iconString;
    if (fromLeader) {
        iconString = @"icon1.png";
    } else {
        iconString = [NSString stringWithFormat:@"%@%i%@", @"icon", id, @".png"];
    }
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
    
    static NSString *tableIdentifier = @"MessageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentifier];
    }
    
    
    Message *message = [_chatSource objectAtIndex:indexPath.row];
    if ([message.uId isEqualToString:[ConnectionManager shared].userID]) {
        cell = [self selfChatBubble:message.message cell:cell];
    } else {
        cell = [self othersChatBubble:message.message cell:cell avatarID:[[_avatarForUser objectForKey:message.uId] intValue] fromLeader:message.fromLeader];
    }
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[_chatSource addObject:@"Hello! My name is Roger Sabonis and I work for the city. Please stop protesting. People might get mad..."];
    //[tableView reloadData];
}









@end
