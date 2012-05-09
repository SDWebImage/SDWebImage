//
//  DetailViewController.h
//  SDWebImage Demo
//
//  Created by Olivier Poitrey on 09/05/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) NSURL *imageURL;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end
