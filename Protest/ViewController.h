//
//  ViewController.h
//  Protest
//
//  Created by John Rogers on 9/2/14.
//  Copyright (c) 2014 metacupcake. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConnectionManager.h"
#import "ProtestConfigViewController.h"
#import "ChatViewController.h"
#import "CryptoManager.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
    NSMutableArray *tableSource;
}

@property (nonatomic, strong) UIButton *startProtestButton;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
