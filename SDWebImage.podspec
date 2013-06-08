Pod::Spec.new do |s|
  s.name = 'SDWebImage'
  s.version = '3.2'
  s.platform = :ios, '5.0'
  s.license = 'MIT'
  s.summary = 'Asynchronous image downloader with cache support with an UIImageView category.'
  s.homepage = 'https://github.com/rs/SDWebImage'
  s.author = { 'Olivier Poitrey' => 'rs@dailymotion.com' }
  s.source = { :git => 'https://github.com/rs/SDWebImage.git', :tag => '3.2' }

  s.description = 'This library provides a category for UIImageView with support for remote '      \
                  'images coming from the web. It provides an UIImageView category adding web '    \
                  'image and cache management to the Cocoa Touch framework, an asynchronous '      \
                  'image downloader, an asynchronous memory + disk image caching with automatic '  \
                  'cache expiration handling, a guarantee that the same URL won\'t be downloaded ' \
                  'several times, a guarantee that bogus URLs won\'t be retried again and again, ' \
                  'and performances!'

  s.requires_arc = true
  s.source_files = 'SDWebImage/{NS,SD,UI}*.{h,m}'
  s.framework = 'ImageIO'

  s.dependency 'libwebp'

  # TODO currently CocoaPods always tries to install the subspec even if the dependency is on just 'SDWebImage'
  s.subspec 'MapKit' do |mk|
    mk.source_files = 'SDWebImage/MKAnnotationView+WebCache.*'
    mk.framework = 'MapKit'
  end
end
