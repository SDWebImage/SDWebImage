/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDInternalMacros.h"

os_log_t sd_getDefaultLog(void) {
    static dispatch_once_t onceToken;
    static os_log_t log;
    dispatch_once(&onceToken, ^{
        log = os_log_create("com.hackemist.SDWebImage", "Default");
    });
    return log;
}

void sd_executeCleanupBlock (__strong sd_cleanupBlock_t *block) {
    (*block)();
}
