
# there is not a podspec in the libwebp project, 
# so I will copy a podspec to the project folder,
# and will remove the podspec after pod install.
require 'fileutils'
FileUtils.cp('vendors/libwebp.podspec.json', 'vendors/libwebp/')
post_install do |installer|
  FileUtils.rm('vendors/libwebp/libwebp.podspec.json')
end

# use_frameworks!

workspace 'SDWebImage'

################################ Demo ################################
target 'SDWebImage iOS Demo' do
  project 'Examples/SDWebImage Demo'
  platform :ios, '8.0'
  pod 'FLAnimatedImage', :path=>'vendors/FLAnimatedImage'
  pod 'libwebp', :path=>'vendors/libwebp'
end

target 'SDWebImage OSX Demo' do
  project 'Examples/SDWebImage Demo'
  platform :osx
  pod 'libwebp', :path=>'vendors/libwebp'
end

target 'SDWebImage Watch Demo' do
  project 'Examples/SDWebImage Demo'
  platform :watchos
  pod 'libwebp', :path=>'vendors/libwebp'
end
  
target 'SDWebImage Watch Demo Extension' do
  project 'Examples/SDWebImage Demo'
  platform :watchos
  pod 'libwebp', :path=>'vendors/libwebp'
end

target 'SDWebImage TV Demo' do
  project 'Examples/SDWebImage Demo'
  platform :tvos
  pod 'libwebp', :path=>'vendors/libwebp'
end

################################ Tests ################################
target 'Tests' do
  project 'Tests/SDWebImage Tests'
  platform :ios, '8.0'
  pod 'Expecta'
  pod 'SDWebImage', :path=>'SDWebImage.podspec'
  pod 'SDWebImage/WebP', :path=>'SDWebImage.podspec'
  pod 'SDWebImage/MapKit', :path=>'SDWebImage.podspec'
  pod 'SDWebImage/GIF', :path=>'SDWebImage.podspec'
end
