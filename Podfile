use_frameworks!

def all_example_pods
  pod 'SDWebImage/MapKit', :path => './'
  pod 'SDWebImageWebPCoder', :git => 'https://github.com/SDWebImage/SDWebImageWebPCoder.git', :branch => 'master'
end

def watch_example_pods
  pod 'SDWebImage/Core', :path => './'
  pod 'SDWebImageWebPCoder', :git => 'https://github.com/SDWebImage/SDWebImageWebPCoder.git', :branch => 'master'
end

def all_test_pods
  pod 'SDWebImage/MapKit', :path => './'
  pod 'Expecta'
  pod 'KVOController'
  pod 'SDWebImageWebPCoder', :git => 'https://github.com/SDWebImage/SDWebImageWebPCoder.git', :branch => 'master'
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
