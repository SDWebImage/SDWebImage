Pod::Spec.new do |s|
  s.name = 'SDWebImage'
  s.version = '5.12.0'

  s.osx.deployment_target = '10.11'
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.license = 'MIT'
  s.summary = 'Asynchronous image downloader with cache support with an UIImageView category.'
  s.homepage = 'https://github.com/SDWebImage/SDWebImage'
  s.author = { 'Olivier Poitrey' => 'rs@dailymotion.com' }
  s.source = { :git => 'https://github.com/SDWebImage/SDWebImage.git', :tag => s.version.to_s }

  s.description = 'This library provides a category for UIImageView with support for remote '      \
                  'images coming from the web. It provides an UIImageView category adding web '    \
                  'image and cache management to the Cocoa Touch framework, an asynchronous '      \
                  'image downloader, an asynchronous memory + disk image caching with automatic '  \
                  'cache expiration handling, a guarantee that the same URL won\'t be downloaded ' \
                  'several times, a guarantee that bogus URLs won\'t be retried again and again, ' \
                  'and performances!'

  s.requires_arc = true
  s.framework = 'ImageIO'
  
  s.default_subspec = 'Core'

  s.pod_target_xcconfig = {
    'SUPPORTS_MACCATALYST' => 'YES',
    'DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER' => 'NO'
  }

  s.subspec 'Core' do |core|
    core.source_files = 'SDWebImage/Core/*.{h,m}', 'WebImage/SDWebImage.h', 'SDWebImage/Private/*.{h,m}'
    core.private_header_files = 'SDWebImage/Private/*.h'
  end

  s.subspec 'MapKit' do |mk|
    mk.osx.deployment_target = '10.11'
    mk.ios.deployment_target = '9.0'
    mk.tvos.deployment_target = '9.0'
    mk.source_files = 'SDWebImageMapKit/MapKit/*.{h,m}'
    mk.framework = 'MapKit'
    mk.dependency 'SDWebImage/Core'
  end
end
