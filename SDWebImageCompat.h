//
//  SDWebImageCompat.h
//  SDWebImageCompat
//
//  Created by Jamie Pinkham on 3/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <TargetConditionals.h>

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#ifndef UIImage
#define UIImage NSImage
#endif
#ifndef UIImageView
#define UIImageView NSImageView
#endif
#else
#import <UIKit/UIKit.h>
#endif
