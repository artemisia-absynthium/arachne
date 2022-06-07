Pod::Spec.new do |s|
  s.name             = 'Arachne'
  s.version          = '0.4.0'
  s.summary          = 'Networking layer for apps using Swift Concurrency.'
  s.homepage         = 'https://arachne.netlify.app'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'artemisia-absynthium'
  s.source           = { :git => 'https://github.com/artemisia-absynthium/arachne.git', :tag => s.version.to_s }
  s.swift_version = '5.5'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '7.0'

  s.source_files = 'Sources/Arachne/**/*.swift'
end
