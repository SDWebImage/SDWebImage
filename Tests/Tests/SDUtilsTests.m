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
#import "SDInternalMacros.h"

@interface SDUtilsTests : SDTestCase

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
