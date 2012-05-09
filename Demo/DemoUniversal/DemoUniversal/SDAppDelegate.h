//
//  SDAppDelegate.h
//  DemoUniversal
//
//  Created by Eli Wang on 4/17/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SDViewController;

@interface SDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SDViewController *viewController;

@end
