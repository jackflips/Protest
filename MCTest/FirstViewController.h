//
//  FirstViewController.h
//  MCTest
//
//  Created by John Rogers on 4/5/14.
//  Copyright (c) 2014 John Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"

@interface FirstViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITextField *txtMessage;
@property (strong, nonatomic) IBOutlet UILabel *protestName;
@property (strong, nonatomic) IBOutlet UITableView *chatTable;
@property (strong, nonatomic) NSMutableArray *chatSource;
@property (strong, nonatomic) NSMutableArray *availAvatars;
@property (strong, nonatomic) NSMutableDictionary *avatarForUser;


- (void)addMessage:(Message*)message;
- (void)protestNameCallback:(NSString*)name;


@end
