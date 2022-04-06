Pod::Spec.new do |s|
  s.name             = 'Arachne'
  s.version          = '0.3.0'
  s.summary          = 'Networking layer for Combine apps written in Swift.'
  s.homepage         = 'https://github.com/artemisia-absynthium/arachne'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'artemisia-absynthium'
  s.source           = { :git => 'https://github.com/artemisia-absynthium/arachne.git', :tag => s.version.to_s }
  s.swift_version = '5.0'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '7.0'

  s.source_files = 'Sources/Arachne/**/*'
end
