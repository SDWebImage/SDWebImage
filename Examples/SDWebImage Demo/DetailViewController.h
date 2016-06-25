//
//  DetailViewController.h
//  SDWebImage Demo
//
//  Created by Olivier Poitrey on 09/05/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/SDWebImageManager.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) NSURL *imageURL;
@property (copy, nonatomic) SDWebImageTransformDownloadedImageBlock transformImage;
@property (copy, nonatomic) NSString *transformKey;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end
