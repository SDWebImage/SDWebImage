/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDDiskCache.h"
#import "SDImageCacheConfig.h"
#import "SDFileAttributeHelper.h"
#import <CommonCrypto/CommonDigest.h>

static NSString * const SDDiskCacheExtendedAttributeName = @"com.hackemist.SDDiskCache";

/// One cache file candidate for the size-based cleanup pass in `removeExpiredData`.
/// `url` is owned by the `cacheFiles` dictionary, which outlives every heap operation below,
/// so it's held unretained to keep the heap a cheap-to-swap POD array. The content date is
/// unboxed once into a primitive so the heap comparisons don't pay for `-[NSDate compare:]`
/// message sends (ordering is unchanged: `-[NSDate compare:]` orders by this very value).
typedef struct {
    __unsafe_unretained NSURL *url;
    NSTimeInterval date;
    NSUInteger size;
} SDDiskCacheEntry;

/// Restore the min-heap invariant (oldest content date at the root) for the subtree rooted at `index`. O(log n).
static void SDDiskCacheHeapSiftDown(SDDiskCacheEntry * _Nonnull heap, NSUInteger count, NSUInteger index) {
    while (YES) {
        NSUInteger oldest = index;
        NSUInteger left = index * 2 + 1;
        NSUInteger right = left + 1;
        if (left < count && heap[left].date < heap[oldest].date) {
            oldest = left;
        }
        if (right < count && heap[right].date < heap[oldest].date) {
            oldest = right;
        }
        if (oldest == index) {
            break;
        }
        SDDiskCacheEntry temp = heap[index];
        heap[index] = heap[oldest];
        heap[oldest] = temp;
        index = oldest;
    }
}

/// Heapify an unordered array in place using Floyd's bottom-up algorithm. O(n), no comparison for the leaf half.
static void SDDiskCacheHeapBuild(SDDiskCacheEntry * _Nonnull heap, NSUInteger count) {
    // Iterate the internal nodes backwards. `count / 2` is one past the last internal node,
    // so the loop counter is kept 1-based to stay safe on the unsigned type.
    for (NSUInteger i = count / 2; i > 0; i--) {
        SDDiskCacheHeapSiftDown(heap, count, i - 1);
    }
}

/// Remove and return the entry with the oldest content date, shrinking `count` by one. O(log n).
static SDDiskCacheEntry SDDiskCacheHeapPopOldest(SDDiskCacheEntry * _Nonnull heap, NSUInteger * _Nonnull count) {
    SDDiskCacheEntry oldest = heap[0];
    *count -= 1;
    if (*count > 0) {
        heap[0] = heap[*count];
        SDDiskCacheHeapSiftDown(heap, *count, 0);
    }
    return oldest;
}

@interface SDDiskCache ()

@property (nonatomic, copy) NSString *diskCachePath;
@property (nonatomic, strong, nonnull) NSFileManager *fileManager;

@end

@implementation SDDiskCache

- (instancetype)init {
    NSAssert(NO, @"Use `initWithCachePath:` with the disk cache path");
    return nil;
}

#pragma mark - SDcachePathForKeyDiskCache Protocol
- (instancetype)initWithCachePath:(NSString *)cachePath config:(nonnull SDImageCacheConfig *)config {
    if (self = [super init]) {
        _diskCachePath = cachePath;
        _config = config;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    if (self.config.fileManager) {
        self.fileManager = self.config.fileManager;
    } else {
        self.fileManager = [NSFileManager new];
    }
  
    [self createDirectory];
}

- (BOOL)containsDataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    
    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    if (!exists) {
        exists = [self.fileManager fileExistsAtPath:filePath.stringByDeletingPathExtension];
    }
    
    return exists;
}

- (NSData *)dataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    // if filePath is nil or (null)，framework will crash with this：
    // Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[_NSPlaceholderData initWithContentsOfFile:options:maxLength:error:]: nil file argument'
    if (filePath == nil || [@"(null)" isEqualToString: filePath]) {
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath options:self.config.diskCacheReadingOptions error:nil];
    if (data) {
        [[NSURL fileURLWithPath:filePath] setResourceValue:[NSDate date] forKey:NSURLContentAccessDateKey error:nil];
        return data;
    }
    
    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    filePath = filePath.stringByDeletingPathExtension;
    data = [NSData dataWithContentsOfFile:filePath options:self.config.diskCacheReadingOptions error:nil];
    if (data) {
        [[NSURL fileURLWithPath:filePath] setResourceValue:[NSDate date] forKey:NSURLContentAccessDateKey error:nil];
        return data;
    }
    
    return nil;
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    NSParameterAssert(data);
    NSParameterAssert(key);
    
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    // transform to NSURL
    NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey isDirectory:NO];
    
    [data writeToURL:fileURL options:self.config.diskCacheWritingOptions error:nil];
}

- (NSData *)extendedDataForKey:(NSString *)key {
    NSParameterAssert(key);
    
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    
    NSData *extendedData = [SDFileAttributeHelper extendedAttribute:SDDiskCacheExtendedAttributeName atPath:cachePathForKey traverseLink:NO error:nil];
    
    return extendedData;
}

- (void)setExtendedData:(NSData *)extendedData forKey:(NSString *)key {
    NSParameterAssert(key);
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    
    if (!extendedData) {
        // Remove
        [SDFileAttributeHelper removeExtendedAttribute:SDDiskCacheExtendedAttributeName atPath:cachePathForKey traverseLink:NO error:nil];
    } else {
        // Override
        [SDFileAttributeHelper setExtendedAttribute:SDDiskCacheExtendedAttributeName value:extendedData atPath:cachePathForKey traverseLink:NO overwrite:YES error:nil];
    }
}

- (void)removeDataForKey:(NSString *)key {
    NSParameterAssert(key);
    NSString *filePath = [self cachePathForKey:key];
    [self.fileManager removeItemAtPath:filePath error:nil];
}

- (void)removeAllData {
    [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
    [self createDirectory];
}

- (void)createDirectory {
  [self.fileManager createDirectoryAtPath:self.diskCachePath
          withIntermediateDirectories:YES
                           attributes:nil
                                error:NULL];
  
  // disable iCloud backup
  if (self.config.shouldDisableiCloud) {
      // ignore iCloud backup resource value error
      [[NSURL fileURLWithPath:self.diskCachePath isDirectory:YES] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
  }
}

- (void)removeExpiredData {
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    
    // Compute content date key to be used for tests
    NSURLResourceKey cacheContentDateKey;
    switch (self.config.diskCacheExpireType) {
        case SDImageCacheConfigExpireTypeModificationDate:
            cacheContentDateKey = NSURLContentModificationDateKey;
            break;
        case SDImageCacheConfigExpireTypeCreationDate:
            cacheContentDateKey = NSURLCreationDateKey;
            break;
        case SDImageCacheConfigExpireTypeChangeDate:
            cacheContentDateKey = NSURLAttributeModificationDateKey;
            break;
        case SDImageCacheConfigExpireTypeAccessDate:
        default:
            cacheContentDateKey = NSURLContentAccessDateKey;
            break;
    }
    
    NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, cacheContentDateKey, NSURLTotalFileAllocatedSizeKey];
    
    // This enumerator prefetches useful properties for our cache files.
    NSDirectoryEnumerator<NSURL *> *fileEnumerator = [self.fileManager enumeratorAtURL:diskCacheURL
                                               includingPropertiesForKeys:resourceKeys
                                                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                                             errorHandler:NULL];
    
    NSDate *expirationDate = (self.config.maxDiskAge < 0) ? nil: [NSDate dateWithTimeIntervalSinceNow:-self.config.maxDiskAge];
    NSMutableDictionary<NSURL *, NSDictionary<NSString *, id> *> *cacheFiles = [NSMutableDictionary dictionary];
    NSUInteger currentCacheSize = 0;
    
    // Enumerate all of the files in the cache directory.  This loop has two purposes:
    //
    //  1. Removing files that are older than the expiration date.
    //  2. Storing file attributes for the size-based cleanup pass.
    NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileEnumerator) {
        @autoreleasepool {
            NSError *error;
            NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
            
            // Skip directories and errors.
            if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            // Remove files that are older than the expiration date;
            NSDate *modifiedDate = resourceValues[cacheContentDateKey];
            if (expirationDate && [[modifiedDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
            
            // Store a reference to this file and account for its total size.
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
            cacheFiles[fileURL] = resourceValues;
        }
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        [self.fileManager removeItemAtURL:fileURL error:nil];
    }
    
    // If our remaining disk cache exceeds a configured maximum size, perform a second
    // size-based cleanup pass.  We delete the oldest files first.
    NSUInteger maxDiskSize = self.config.maxDiskSize;
    if (maxDiskSize > 0 && currentCacheSize > maxDiskSize) {
        // Target half of our maximum cache size for this cleanup pass.
        const NSUInteger desiredCacheSize = maxDiskSize / 2;
        
        // A full sort of every remaining cache file is more work than we need: we only ever
        // consume the oldest `k` entries, so heapify in O(n) and pop just those in O(k log n)
        // instead of ordering all n in O(n log n). The content date is also unboxed to a
        // primitive up front, so the heap comparisons are plain double compares rather than
        // `-[NSDate compare:]` message sends.
        NSUInteger heapCount = cacheFiles.count;
        SDDiskCacheEntry *heap = heapCount > 0 ? malloc(heapCount * sizeof(SDDiskCacheEntry)) : NULL;
        if (heap) {
            __block NSUInteger index = 0;
            [cacheFiles enumerateKeysAndObjectsUsingBlock:^(NSURL *fileURL, NSDictionary<NSString *, id> *resourceValues, BOOL *stop) {
                heap[index].url = fileURL;
                heap[index].date = [(NSDate *)resourceValues[cacheContentDateKey] timeIntervalSinceReferenceDate];
                heap[index].size = [(NSNumber *)resourceValues[NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
                index++;
            }];
            SDDiskCacheHeapBuild(heap, heapCount);

            // Delete files, oldest first, until we fall below our desired cache size.
            while (heapCount > 0) {
                SDDiskCacheEntry entry = SDDiskCacheHeapPopOldest(heap, &heapCount);
                if ([self.fileManager removeItemAtURL:entry.url error:nil]) {
                    currentCacheSize -= entry.size;

                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
            free(heap);
        } else {
            // Allocation failed, fall back to sorting the remaining cache files by their
            // last modification time or last access time (oldest first).
            NSArray<NSURL *> *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                     usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                         return [obj1[cacheContentDateKey] compare:obj2[cacheContentDateKey]];
                                                                     }];

            // Delete files until we fall below our desired cache size.
            for (NSURL *fileURL in sortedFiles) {
                if ([self.fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary<NSString *, id> *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;

                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
    }
}

- (nullable NSString *)cachePathForKey:(NSString *)key {
    NSParameterAssert(key);
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

- (NSUInteger)totalSize {
    NSUInteger size = 0;

    // Use URL-based enumerator instead of Path(NSString *)-based enumerator to reduce
    // those objects(ex. NSPathStore2/_NSCFString/NSConcreteData) created during traversal.
    // Even worse, those objects are added into AutoreleasePool, in background threads, 
    // the time to release those objects is undifined(according to the usage of CPU)
    // It will truely consumes a lot of VM, up to cause OOMs.
    @autoreleasepool {
        NSURL *pathURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSDirectoryEnumerator<NSURL *> *fileEnumerator = [self.fileManager enumeratorAtURL:pathURL
                                                  includingPropertiesForKeys:@[NSURLFileSizeKey]
                                                                     options:(NSDirectoryEnumerationOptions)0
                                                                errorHandler:NULL];
        
        for (NSURL *fileURL in fileEnumerator) {
            @autoreleasepool {
                NSNumber *fileSize;
                [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
                size += fileSize.unsignedIntegerValue;
            }
        }
    }
    return size;
}

- (NSUInteger)totalCount {
    NSUInteger count = 0;
    @autoreleasepool {
        NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSDirectoryEnumerator<NSURL *> *fileEnumerator = [self.fileManager enumeratorAtURL:diskCacheURL includingPropertiesForKeys:@[] options:(NSDirectoryEnumerationOptions)0 errorHandler:nil];
        count = fileEnumerator.allObjects.count;
    }
    return count;
}

#pragma mark - Cache paths

- (nullable NSString *)cachePathForKey:(nullable NSString *)key inPath:(nonnull NSString *)path {
    NSString *filename = SDDiskCacheFileNameForKey(key);
    return [path stringByAppendingPathComponent:filename];
}

- (void)moveCacheDirectoryFromPath:(nonnull NSString *)srcPath toPath:(nonnull NSString *)dstPath {
    NSParameterAssert(srcPath);
    NSParameterAssert(dstPath);
    // Check if old path is equal to new path
    if ([srcPath isEqualToString:dstPath]) {
        return;
    }
    BOOL isDirectory;
    // Check if old path is directory
    if (![self.fileManager fileExistsAtPath:srcPath isDirectory:&isDirectory] || !isDirectory) {
        return;
    }
    // Check if new path is directory
    if (![self.fileManager fileExistsAtPath:dstPath isDirectory:&isDirectory] || !isDirectory) {
        if (!isDirectory) {
            // New path is not directory, remove file
            [self.fileManager removeItemAtPath:dstPath error:nil];
        }
        NSString *dstParentPath = [dstPath stringByDeletingLastPathComponent];
        // Creates any non-existent parent directories as part of creating the directory in path
        if (![self.fileManager fileExistsAtPath:dstParentPath]) {
            [self.fileManager createDirectoryAtPath:dstParentPath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        // New directory does not exist, rename directory
        [self.fileManager moveItemAtPath:srcPath toPath:dstPath error:nil];
        // disable iCloud backup
        if (self.config.shouldDisableiCloud) {
            // ignore iCloud backup resource value error
            [[NSURL fileURLWithPath:dstPath isDirectory:YES] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
    } else {
        // New directory exist, merge the files
        NSURL *srcURL = [NSURL fileURLWithPath:srcPath isDirectory:YES];
        NSDirectoryEnumerator<NSURL *> *srcDirEnumerator = [self.fileManager enumeratorAtURL:srcURL
                                                               includingPropertiesForKeys:@[]
                                                                                  options:(NSDirectoryEnumerationOptions)0
                                                                             errorHandler:NULL];
        for (NSURL *url in srcDirEnumerator) {
            @autoreleasepool {
                NSString *dstFilePath = [dstPath stringByAppendingPathComponent:url.lastPathComponent];
                NSURL *dstFileURL = [NSURL fileURLWithPath:dstFilePath isDirectory:NO];
                [self.fileManager moveItemAtURL:url toURL:dstFileURL error:nil];
            }
        }
        
        // Remove the old path
        [self.fileManager removeItemAtURL:srcURL error:nil];
    }
}

#pragma mark - Hash

static inline NSString *SDSanitizeFileNameString(NSString * _Nullable fileName) {
    if ([fileName length] == 0) {
        return fileName;
    }
    // note: `:` is the only invalid char on Apple file system
    // but `/` or `\` is valid
    // \0 is also special case (which cause Foundation API treat the C string as EOF)
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\0:"];
    return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
}

#define SD_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline NSString * _Nonnull SDDiskCacheFileNameForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *ext;
    // 1. Use URL path extname if valid
    NSURL *keyURL = [NSURL URLWithString:key];
    if (keyURL) {
        ext = keyURL.pathExtension;
    }
    // 2. Use file extname if valid
    if (!ext) {
        ext = key.pathExtension;
    }
    // 3. Check if extname valid on file system
    ext = SDSanitizeFileNameString(ext);
    // File system has file name length limit, we need to check if ext is too long, we don't add it to the filename
    if (ext.length > SD_MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return filename;
}
#pragma clang diagnostic pop

@end
