//
//  SDViewController.h
//  DemoUniversal
//
//  Created by Eli Wang on 4/17/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UITextField *urlField;
- (IBAction)loadButtonTouched:(id)sender;
@end
