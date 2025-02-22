/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import "SDWeakProxy.h"
#import "SDDisplayLink.h"
#import "SDInternalMacros.h"
#import "SDFileAttributeHelper.h"
#import "UIColor+SDHexString.h"

@interface SDUtilsTests : SDTestCase

@property (nonatomic) NSTimeInterval duration;

@end

@implementation SDUtilsTests

- (void)testSDWeakProxy {
    NSObject *object = [NSObject new];
    SDWeakProxy *proxy = [SDWeakProxy proxyWithTarget:object];
    SEL sel = @selector(hash);
    NSMethodSignature *signature = [proxy methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [proxy forwardInvocation:invocation];
    void *returnValue;
    [invocation getReturnValue:&returnValue];
    expect(returnValue).beNil();
    expect([((NSObject *)proxy) forwardingTargetForSelector:sel]).equal(object);
    expect(proxy.isProxy).beTruthy();
    expect([proxy respondsToSelector:sel]).equal([object respondsToSelector:sel]);
    expect([proxy isEqual:object]).beTruthy();
    expect(proxy.hash).equal(object.hash);
    expect(proxy.superclass).equal(object.superclass);
    expect(proxy.class).equal(object.class);
    expect([proxy isKindOfClass:NSObject.class]).equal([object isKindOfClass:NSObject.class]);
    expect([proxy isMemberOfClass:NSObject.class]).equal([object isMemberOfClass:NSObject.class]);
    expect([proxy conformsToProtocol:@protocol(NSObject)]).equal([object conformsToProtocol:@protocol(NSObject)]);
    expect([proxy.description isEqualToString:object.description]).beTruthy();
    expect([proxy.debugDescription isEqualToString:object.debugDescription]).beTruthy();
}

- (void)testSDDisplayLink {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Display Link Stop"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Display Link Start"];
    SDDisplayLink *displayLink = [SDDisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidRefresh:)];
    [displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    [displayLink start];
    expect(displayLink.isRunning).beTruthy();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(displayLink.isRunning).beTruthy();
        NSTimeInterval duration = self.duration; // Should be 1, 200ms accuracy
        expect(duration).beCloseToWithin(1, 0.2);
        [displayLink stop];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(displayLink.isRunning).beFalsy();
        [displayLink start];
        [expectation1 fulfill];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(displayLink.isRunning).beTruthy();
        [displayLink stop];
        [expectation2 fulfill];
    });
    [self waitForExpectationsWithCommonTimeout];
}

- (void)displayLinkDidRefresh:(SDDisplayLink *)displayLink {
    NSTimeInterval duration = displayLink.duration; // Running value
    self.duration += duration;
}

- (void)testSDFileAttributeHelper {
    NSData *fileData = [@"File Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *extendedData = [@"Extended Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filePath = @"/tmp/file.dat";
    [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
    [fileData writeToFile:filePath atomically:YES];
    BOOL exist = [NSFileManager.defaultManager fileExistsAtPath:filePath];
    expect(exist).beTruthy();
    
    NSArray *names = [SDFileAttributeHelper extendedAttributeNamesAtPath:filePath traverseLink:NO error:nil];
    expect(names.count).equal(0);
    
    NSString *attr = @"com.hackemist.test";
    [SDFileAttributeHelper setExtendedAttribute:attr value:extendedData atPath:filePath traverseLink:NO overwrite:YES error:nil];
    
    BOOL hasAttr =[SDFileAttributeHelper hasExtendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(hasAttr).beTruthy();
    
    names = [SDFileAttributeHelper extendedAttributeNamesAtPath:filePath traverseLink:NO error:nil];
    expect(names.count).equal(1);
    expect(names.firstObject).equal(attr);
    
    NSData *queriedData = [SDFileAttributeHelper extendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(extendedData).equal(queriedData);
    
    BOOL removed = [SDFileAttributeHelper removeExtendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(removed).beTruthy();
    
    hasAttr = [SDFileAttributeHelper hasExtendedAttribute:attr atPath:filePath traverseLink:NO error:nil];
    expect(hasAttr).beFalsy();
}

- (void)testSDGraphicsImageRenderer {
    // Main Screen
    SDGraphicsImageRendererFormat *format = SDGraphicsImageRendererFormat.preferredFormat;
#if SD_UIKIT
#if SD_VISION
    CGFloat screenScale = UITraitCollection.currentTraitCollection.displayScale;
#else
    CGFloat screenScale = [UIScreen mainScreen].scale;
#endif
#elif SD_MAC
    CGFloat screenScale = [NSScreen mainScreen].backingScaleFactor;
#endif
    expect(format.scale).equal(screenScale);
    expect(format.opaque).beFalsy();
    expect(format.preferredRange).equal(SDGraphicsImageRendererFormatRangeAutomatic);
    CGSize size = CGSizeMake(100, 100);
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:size format:format];
#if SD_MAC
    // GitHub action's Mac does not connect to a display, so the ImageRenderer color space is wrong :(
    if (SDTestCase.isCI) {
        return;
    }
#endif
    UIColor *color = UIColor.redColor;
    NSLog(@"Draw Color ColorSpace: %@", color.CGColor);
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }];
    expect(image.scale).equal(format.scale);
    UIColor *testColor = [image sd_colorAtPoint:CGPointMake(50, 50)];
    NSLog(@"Test Color ColorSpace: %@", testColor.CGColor);
    expect(testColor.sd_hexString).equal(color.sd_hexString);
    
    UIColor *grayscaleColor = UIColor.blackColor;
    UIImage *grayscaleImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetFillColorWithColor(context, [grayscaleColor CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }];
    expect([grayscaleImage sd_colorAtPoint:CGPointMake(50, 50)].sd_hexString).equal(grayscaleColor.sd_hexString);
}

- (void)testSDScaledImageForKey {
    // Test nil
    expect(SDScaledImageForKey(nil, nil)).beNil();
    // Test @2x
    NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
    UIImage * image = [UIImage sd_imageWithGIFData:data];
    expect(image.sd_isAnimated).beTruthy();
    expect(image.scale).equal(1);
    
    UIImage *scaledImage = SDScaledImageForKey(@"test@2x.gif", image);
    expect(scaledImage.scale).equal(2);
}

- (void)testSDCallbackQueue {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"SDCallbackQueue SafeExecute works"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"SDCallbackQueue Dispatch works"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"SDCallbackQueue Invoke works"];
    dispatch_queue_t queue = dispatch_queue_create("testSDCallbackQueue", NULL);
    SDCallbackQueue *callbackQueue = [[SDCallbackQueue alloc] initWithDispatchQueue:queue];
    __block BOOL called = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [callbackQueue sync:^{
        called = YES;
    }];
#pragma clang diagnostic pop
    expect(called).beTruthy();
    
    __block BOOL called1 = NO;
    callbackQueue.policy = SDCallbackPolicySafeExecute;
    dispatch_async(queue, ^{
        // Should execute in sync
        [callbackQueue async:^{
            called1 = YES;
            [expectation1 fulfill];
        }];
        expect(called1).beTruthy();
    });
    
    SDCallbackQueue *callbackQueue2 = [[SDCallbackQueue alloc] initWithDispatchQueue:queue];
    __block BOOL called2 = NO;
    callbackQueue2.policy = SDCallbackPolicyDispatch;
    dispatch_async(queue, ^{
        // Should execute in async
        [callbackQueue2 async:^{
            called2 = YES;
            [expectation2 fulfill];
        }];
        expect(called2).beFalsy();
    });
    
    SDCallbackQueue *callbackQueue3 = [[SDCallbackQueue alloc] initWithDispatchQueue:queue];
    __block BOOL called3 = NO;
    callbackQueue3.policy = SDCallbackPolicyInvoke;
    dispatch_async(queue, ^{
        // Should execute in sync
        [callbackQueue3 async:^{
            called3 = YES;
            [expectation3 fulfill];
        }];
        expect(called3).beTruthy();
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testInternalMacro {
    @weakify(self);
    @onExit {
        @strongify(self);
        expect(self).notTo.beNil();
    };
}

#pragma mark - Helper

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"gif"];
}

@end
