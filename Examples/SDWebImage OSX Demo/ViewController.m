//
//  ViewController.m
//  SDWebImage OSX Demo
//
//  Created by Bogdan on 12/06/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "ViewController.h"

@import SDWebImage;

@interface ViewController ()

@property (weak) IBOutlet NSImageView *imageView1;
@property (weak) IBOutlet NSImageView *imageView2;
@property (weak) IBOutlet NSImageView *imageView3;
@property (weak) IBOutlet NSImageView *imageView4;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NOTE: https links or authentication ones do not work (there is a crash)
    
//     Do any additional setup after loading the view.
    [self.imageView1 sd_setImageWithURL:[NSURL URLWithString:@"http://assets.sbnation.com/assets/2512203/dogflops.gif"]];
    [self.imageView2 sd_setImageWithURL:[NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"]];
    [self.imageView3 sd_setImageWithURL:[NSURL URLWithString:@"http://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage000.jpg"]];
    [self.imageView4 sd_setImageWithURL:[NSURL URLWithString:@"http://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage001.jpg"]];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
