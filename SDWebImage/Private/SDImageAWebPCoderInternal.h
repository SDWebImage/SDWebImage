/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <Foundation/Foundation.h>
#import "SDImageAWebPCoder.h"

// kUTTypeWebP seems not defined in public UTI framework, Apple use the hardcode string, we define them :)
#define kSDUTTypeWebP ((__bridge CFStringRef)@"org.webmproject.webp")

@interface SDImageAWebPCoder ()

+ (BOOL)canDecodeFromWebPFormat;
+ (BOOL)canEncodeToWebPFormat;

@end
