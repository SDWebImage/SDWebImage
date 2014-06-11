using System;

namespace SDWebImage
{
	public enum SDWebImageDownloaderOptions 
	{
		LowPriority = 1 << 0,
		ProgressiveDownload = 1 << 1,
		UseNSURLCache = 1 << 2,
		IgnoreCachedResponse = 1 << 3
	}

	public enum SDWebImageDownloaderExecutionOrder
	{
		FIFOExecutionOrder,
		LIFOExecutionOrder
	}

	public enum SDWebImageOptions
	{
		RetryFailed = 1 << 0,
		LowPriority = 1 << 1,
		CacheMemoryOnly = 1 << 2,
		ProgressiveDownload = 1 << 3,
		RefreshCached = 1 << 4
	}

	public enum SDImageCacheType
	{
		None = 0,
		Disk,
		Memory
	}
}

