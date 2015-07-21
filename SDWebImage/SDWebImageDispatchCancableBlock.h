//@see https://github.com/SebastienThiebaud/dispatch_cancelable_block/blob/master/dispatch_cancelable_block.h
//
//  dispatch_cancelable_block.h
//  sebastienthiebaud.us
//
//  Created by Sebastien Thiebaud on 4/9/14.
//  Copyright (c) 2014 Sebastien Thiebaud. All rights reserved.
//

typedef void(^sd_dispatch_cancelable_block_t)(BOOL cancel);

static sd_dispatch_cancelable_block_t sd_dispatch_after_delay(CGFloat delay, dispatch_block_t block) {
    if (block == nil)
        return nil;
    
    // First we have to create a new dispatch_cancelable_block_t and we also need to copy the block given (if you want more explanations about the __block storage type, read this: https://developer.apple.com/library/ios/documentation/cocoa/conceptual/Blocks/Articles/bxVariables.html#//apple_ref/doc/uid/TP40007502-CH6-SW6
    __block sd_dispatch_cancelable_block_t cancelableBlock = nil;
    __block dispatch_block_t originalBlock = [block copy];
    
    // This block will be executed in NOW() + delay
    sd_dispatch_cancelable_block_t delayBlock = ^(BOOL cancel){
        if (cancel == NO && originalBlock)
            dispatch_async(dispatch_get_main_queue(), originalBlock);
        
        // We don't want to hold any objects in the memory
        originalBlock = nil;
        cancelableBlock = nil;
    };
    
    cancelableBlock = [delayBlock copy];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // We are now in the future (NOW() + delay). It means the block hasn't been canceled so we can execute it
        if (cancelableBlock)
            cancelableBlock(NO);
    });
    
    return cancelableBlock;
}

static void sd_cancel_block(sd_dispatch_cancelable_block_t block) {
    if (block == nil)
        return;
    
    block(YES);
}