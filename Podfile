use_frameworks!

def all_example_pods
  pod 'SDWebImage/MapKit', :path => './'
  pod 'SDWebImageWebPCoder', :git => 'https://github.com/SDWebImage/SDWebImageWebPCoder.git', :branch => 'master'
end

def watch_example_pods
  pod 'SDWebImage/Core', :path => './'
  pod 'SDWebImageWebPCoder', :git => 'https://github.com/SDWebImage/SDWebImageWebPCoder.git', :branch => 'master'
end

def vision_example_pods
  pod 'SDWebImage/MapKit', :path => './'
  pod 'SDWebImageSwiftUI', :git => 'https://github.com/SDWebImage/SDWebImageSwiftUI.git', :branch => 'master'
end

def all_test_pods
  pod 'SDWebImage/MapKit', :path => './'
  # These two Pods seems no longer maintained...
  pod 'Expecta', :podspec => 'Tests/Expecta.podspec'
  pod 'KVOController', :podspec => 'Tests/KVOController.podspec'
end

example_project_path = 'Examples/SDWebImage Demo'
test_project_path = 'Tests/SDWebImage Tests'
workspace 'SDWebImage.xcworkspace'

# Example Project
target 'SDWebImage iOS Demo' do
  project example_project_path
  platform :ios, '9.0'
  all_example_pods
end

target 'SDWebImage OSX Demo' do
  project example_project_path
  platform :osx, '10.11'
  all_example_pods
end

target 'SDWebImage TV Demo' do
  project example_project_path
  platform :tvos, '9.0'
  all_example_pods
end

target 'SDWebImage Watch Demo Extension' do
  project example_project_path
  platform :watchos, '2.0'
  watch_example_pods
end

target 'SDWebImage Vision Demo' do
  project example_project_path
  platform :visionos, '1.0'
  vision_example_pods
end

# Test Project
target 'Tests iOS' do
  project test_project_path
  platform :ios, '9.0'
  all_test_pods
end

target 'Tests Mac' do
  project test_project_path
  platform :osx, '10.11'
  all_test_pods
end

target 'Tests TV' do
  project test_project_path
  platform :tvos, '9.0'
  all_test_pods
end

target 'Tests Vision' do
  project test_project_path
  platform :visionos, '1.0'
  all_test_pods
end

# Inject macro during SDWebImage Demo and Tests
post_install do |installer_representation|
  installer_representation.generated_pod_targets.each do |target|
    if target.pod_name == "SDWebImage"
      build_settings = target.build_settings
      build_settings.each do |configuration, build_setting|
        if configuration == :debug
          config = build_setting.xcconfig
          old_value = config.attributes['GCC_PREPROCESSOR_DEFINITIONS']
          config.attributes['GCC_PREPROCESSOR_DEFINITIONS'] = old_value + ' SD_CHECK_CGIMAGE_RETAIN_SOURCE=1'
          config.save_as(target.xcconfig_path(configuration))
        end
      end
    end
  end
end
