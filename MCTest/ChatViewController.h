//
//  FirstViewController.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "DAKeyboardControl.h"

@interface ChatViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UILabel *protestName;
@property (strong, nonatomic) IBOutlet UITableView *chatTable;
@property (strong, nonatomic) NSMutableArray *chatSource;
@property (strong, nonatomic) NSMutableArray *availAvatars;
@property (strong, nonatomic) NSMutableDictionary *avatarForUser;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UIToolbar *toolBar;

- (void)chatLoaded:(NSString*)protestName;
- (void)addMessage:(Message*)message;


@end
