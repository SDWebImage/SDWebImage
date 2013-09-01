using System;
using System.Drawing;
using MonoTouch.ObjCRuntime;
using MonoTouch.Foundation;
using MonoTouch.UIKit;

namespace SDWebImage 
{
	public delegate void SDWebImageDownloaderCompletedBlock (UIImage image, NSData data, NSError error, bool finished);
	public delegate void SDWebImageDownloaderProgressBlock (int receivedSize, long expectedSize);
	public delegate void SDWebImageCompletedBlock (UIImage image, NSError error, SDImageCacheType cacheType);
	public delegate void SDWebImageCompletedWithFinishedBlock (UIImage image, NSError error, SDImageCacheType cacheType, bool finished);

	public delegate void SDWebImageDoneBlock (UIImage image, SDImageCacheType cacheType);
	public delegate void SDImageCacheCompletionBlock(int fileCount, ulong totalSize);
	public delegate void SDWebImagePrefetcherCompletionBlock(int finishedCount, int skippedCount);
	public delegate string SDWebImageManagerCacheKeyFilterBlock(NSUrl url);
	public delegate void SDWebImageDownloaderOperationCancelBlock();

	[Model, BaseType (typeof (NSObject))]
	public partial interface SDWebImageOperation 
	{
		[Export ("cancel")]
		void Cancel ();
	}

	[BaseType (typeof (NSObject))]
	public partial interface SDWebImageDownloader 
	{
		[Export ("maxConcurrentDownloads")]
		int MaxConcurrentDownloads { get; set; }

		[Export ("executionOrder")]
		SDWebImageDownloaderExecutionOrder ExecutionOrder { get; set; }

		[Static, Export ("sharedDownloader")]
		SDWebImageDownloader SharedDownloader { get; }

		[Export ("setValue:forHTTPHeaderField:")]
		void SetValue (string value, string field);

		[Export ("valueForHTTPHeaderField:")]
		string ValueForHTTPHeaderField (string field);

		[Export ("downloadImageWithURL:options:progress:completed:")]
		SDWebImageOperation DownloadImageWithURL (NSUrl url, SDWebImageDownloaderOptions options, SDWebImageDownloaderProgressBlock progressBlock, SDWebImageDownloaderCompletedBlock completedBlock);
	}

	[BaseType (typeof (NSObject))]
	public partial interface SDImageCache 
	{
		[Export ("maxCacheAge")]
		int MaxCacheAge { get; set; }

		[Export ("maxCacheSize")]
		ulong MaxCacheSize { get; set; }

		[Static, Export ("sharedImageCache")]
		SDImageCache SharedImageCache { get; }

		[Export ("initWithNamespace:")]
		IntPtr Constructor (string ns);

		[Export ("addReadOnlyCachePath:")]
		void AddReadOnlyCachePath (string path);

		[Export ("storeImage:forKey:")]
		void StoreImage (UIImage image, string key);

		[Export ("storeImage:forKey:toDisk:")]
		void StoreImage (UIImage image, string key, bool toDisk);

		[Export ("storeImage:imageData:forKey:toDisk:")]
		void StoreImage (UIImage image, NSData data, string key, bool toDisk);

		[Export ("queryDiskCacheForKey:done:")]
		NSOperation QueryDiskCacheForKey (string key, SDWebImageDoneBlock doneBlock);

		[Export ("imageFromMemoryCacheForKey:")]
		UIImage ImageFromMemoryCacheForKey (string key);

		[Export ("imageFromDiskCacheForKey:")]
		UIImage ImageFromDiskCacheForKey (string key);

		[Export ("removeImageForKey:")]
		void RemoveImageForKey (string key);

		[Export ("removeImageForKey:fromDisk:")]
		void RemoveImageForKey (string key, bool fromDisk);

		[Export ("clearMemory")]
		void ClearMemory ();

		[Export ("clearDisk")]
		void ClearDisk ();

		[Export ("cleanDisk")]
		void CleanDisk ();

		[Export ("getSize")]
		ulong Size { get; }

		[Export ("getDiskCount")]
		int DiskCount { get; }

		[Export ("calculateSizeWithCompletionBlock:")]
		void CalculateSizeWithCompletionBlock (SDImageCacheCompletionBlock completionBlock);
	}

	[Model, BaseType (typeof (NSObject))]
	public partial interface SDWebImageManagerDelegate 
	{
		[Export ("imageManager:shouldDownloadImageForURL:")]
		bool ShouldDownloadImageForURL (SDWebImageManager imageManager, NSUrl imageURL);

		[Export ("imageManager:transformDownloadedImage:withURL:")]
		UIImage TransformDownloadedImage (SDWebImageManager imageManager, UIImage image, NSUrl imageURL);
	}

	[BaseType (typeof (NSObject))]
	public partial interface SDWebImageManager 
	{
		[Export ("delegate", ArgumentSemantic.Assign)]
		SDWebImageManagerDelegate Delegate { get; set; }

		[Export ("imageCache", ArgumentSemantic.Retain)]
		SDImageCache ImageCache { get; }

		[Export ("imageDownloader", ArgumentSemantic.Retain)]
		SDWebImageDownloader ImageDownloader { get; }

		[Export ("cacheKeyFilter", ArgumentSemantic.Retain)]
		SDWebImageManagerCacheKeyFilterBlock CacheKeyFilter { get; set; }

		[Static, Export ("sharedManager")]
		SDWebImageManager SharedManager { get; }

		[Export ("downloadWithURL:options:progress:completed:")]
		SDWebImageOperation DownloadWithURL (NSUrl url, SDWebImageOptions options, SDWebImageDownloaderProgressBlock progressBlock, SDWebImageCompletedWithFinishedBlock completedBlock);

		[Export ("cancelAll")]
		void CancelAll ();

		[Export ("isRunning")]
		bool IsRunning { get; }
	}

	[Category, BaseType (typeof (UIImage))]
	public partial interface ForceDecode_UIImage
	{
		[Static, Export ("decodedImageWithImage:")]
		UIImage DecodedImageWithImage (UIImage image);
	}

	[BaseType (typeof (NSOperation))]
	public partial interface SDWebImageDownloaderOperation : SDWebImageOperation 
	{
		[Export ("request", ArgumentSemantic.Retain)]
		NSUrlRequest Request { get; }

		[Export ("options")]
		SDWebImageDownloaderOptions Options { get; }

		[Export ("initWithRequest:options:progress:completed:cancelled:")]
		IntPtr Constructor (NSUrlRequest request, SDWebImageDownloaderOptions options, SDWebImageDownloaderProgressBlock progressBlock, SDWebImageDownloaderCompletedBlock completedBlock, SDWebImageDownloaderOperationCancelBlock cancelBlock);
	}

	[BaseType (typeof (NSObject))]
	public partial interface SDWebImagePrefetcher
	{
		[Export ("maxConcurrentDownloads")]
		uint MaxConcurrentDownloads { get; set; }

		[Export ("options")]
		SDWebImageOptions Options { get; set; }

		[Static, Export ("sharedImagePrefetcher")]
		SDWebImagePrefetcher SharedImagePrefetcher { get; }

		[Export ("prefetchURLs:")]
		void PrefetchURLs (NSUrl [] urls);

		[Export ("prefetchURLs:completed:")]
		void PrefetchURLs (NSUrl [] urls, SDWebImagePrefetcherCompletionBlock completionBlock);

		[Export ("cancelPrefetching")]
		void CancelPrefetching ();
	}
	
	[Category, BaseType (typeof (UIButton))]
	public partial interface WebCache_UIButton 
	{
		[Export ("setImageWithURL:forState:")]
		void SetImageWithURL (NSUrl url, UIControlState state);

		[Export ("setImageWithURL:forState:placeholderImage:")]
		void SetImageWithURL (NSUrl url, UIControlState state, UIImage placeholder);

		[Export ("setImageWithURL:forState:placeholderImage:options:")]
		void SetImageWithURL (NSUrl url, UIControlState state, UIImage placeholder, SDWebImageOptions options);

		[Export ("setImageWithURL:forState:completed:")]
		void SetImageWithURL (NSUrl url, UIControlState state, SDWebImageCompletedBlock completedBlock);

		[Export ("setImageWithURL:forState:placeholderImage:completed:")]
		void SetImageWithURL (NSUrl url, UIControlState state, UIImage placeholder, SDWebImageCompletedBlock completedBlock);

		[Export ("setImageWithURL:forState:placeholderImage:options:completed:")]
		void SetImageWithURL (NSUrl url, UIControlState state, UIImage placeholder, SDWebImageOptions options, SDWebImageCompletedBlock completedBlock);

		[Export ("setBackgroundImageWithURL:forState:")]
		void SetBackgroundImageWithURL (NSUrl url, UIControlState state);

		[Export ("setBackgroundImageWithURL:forState:placeholderImage:")]
		void SetBackgroundImageWithURL (NSUrl url, UIControlState state, UIImage placeholder);

		[Export ("setBackgroundImageWithURL:forState:placeholderImage:options:")]
		void SetBackgroundImageWithURL (NSUrl url, UIControlState state, UIImage placeholder, SDWebImageOptions options);

		[Export ("setBackgroundImageWithURL:forState:completed:")]
		void SetBackgroundImageWithURL (NSUrl url, UIControlState state, SDWebImageCompletedBlock completedBlock);

		[Export ("setBackgroundImageWithURL:forState:placeholderImage:completed:")]
		void SetBackgroundImageWithURL (NSUrl url, UIControlState state, UIImage placeholder, SDWebImageCompletedBlock completedBlock);

		[Export ("setBackgroundImageWithURL:forState:placeholderImage:options:completed:")]
		void SetBackgroundImageWithURL (NSUrl url, UIControlState state, UIImage placeholder, SDWebImageOptions options, SDWebImageCompletedBlock completedBlock);

		[Export ("cancelCurrentImageLoad")]
		void CancelCurrentImageLoad ();
	}

	[Category, BaseType (typeof (NSData))]
	public partial interface GIF_NSData 
	{
		[Static, Export ("sd_isGIF")]
		bool Sd_isGIF ();
	}

	[Category, BaseType (typeof (UIImage))]
	public partial interface GIF_UIImage 
	{
		[Static, Export ("sd_animatedGIFNamed:")]
		UIImage Sd_animatedGIFNamed (string name);

		[Static, Export ("sd_animatedGIFWithData:")]
		UIImage Sd_animatedGIFWithData (NSData data);

		[Export ("sd_animatedImageByScalingAndCroppingToSize:")]
		UIImage Sd_animatedImageByScalingAndCroppingToSize (SizeF size);
	}

	[Category, BaseType (typeof (UIImage))]
	public partial interface MultiFormat_UIImage 
	{
		[Static, Export ("sd_imageWithData:")]
		UIImage Sd_imageWithData (NSData data);
	}

	[Category, BaseType (typeof (UIImageView))]
	public partial interface WebCache_UIImageView 
	{
		[Export ("setImageWithURL:")]
		void SetImageWithURL (NSUrl url);

		[Export ("setImageWithURL:placeholderImage:")]
		void SetImageWithURL (NSUrl url, UIImage placeholder);

		[Export ("setImageWithURL:placeholderImage:options:")]
		void SetImageWithURL (NSUrl url, UIImage placeholder, SDWebImageOptions options);

		[Export ("setImageWithURL:completed:")]
		void SetImageWithURL (NSUrl url, SDWebImageCompletedBlock completedBlock);

		[Export ("setImageWithURL:placeholderImage:completed:")]
		void SetImageWithURL (NSUrl url, UIImage placeholder, SDWebImageCompletedBlock completedBlock);

		[Export ("setImageWithURL:placeholderImage:options:completed:")]
		void SetImageWithURL (NSUrl url, UIImage placeholder, SDWebImageOptions options, SDWebImageCompletedBlock completedBlock);

		[Export ("setImageWithURL:placeholderImage:options:progress:completed:")]
		void SetImageWithURL (NSUrl url, UIImage placeholder, SDWebImageOptions options, SDWebImageDownloaderProgressBlock progressBlock, SDWebImageCompletedBlock completedBlock);

		[Export ("setAnimationImagesWithURLs:")]
		void SetAnimationImagesWithURLs (NSUrl[] urls);

		[Export ("cancelCurrentImageLoad")]
		void CancelCurrentImageLoad ();

		[Export ("cancelCurrentArrayLoad")]
		void CancelCurrentArrayLoad ();
	}
}

