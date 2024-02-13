Pod::Spec.new do |spec|
  spec.name         = 'KVOController'
  spec.version      = '1.2.0'
  spec.license      =  { :type => 'BSD' }
  spec.homepage     = 'https://github.com/facebook/KVOController'
  spec.authors      = { 'Kimon Tsinteris' => 'kimon@mac.com', 'Nikita Lutsenko' => 'nlutsenko@me.com' }
  spec.summary      = 'Simple, modern, thread-safe key-value observing.'
  spec.description  = <<-DESC
                      KVOController builds on Cocoa's time-tested key-value observing implementation. It offers a simple, modern API, that is also thread safe.
                      Benefits include:
                      Notification using blocks, custom actions, or NSKeyValueObserving callback.
                      No exceptions on observer removal.
                      Implicit observer removal on controller dealloc.
                      Thread-safety with special guards against observer resurrection.
                      DESC
  spec.source       = { :git => 'https://github.com/facebook/KVOController.git', :tag => "v#{spec.version.to_s}" }
  spec.source_files = 'FBKVOController/*.{h,m}'
  spec.requires_arc = true

  spec.ios.deployment_target = '9.0'
  spec.osx.deployment_target = '10.11'
  spec.tvos.deployment_target = '9.0'
  spec.watchos.deployment_target = '2.0'
  spec.visionos.deployment_target = '1.0'
end
