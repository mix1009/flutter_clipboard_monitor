#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint clipboard_monitor.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'clipboard_monitor'
  s.version          = '0.9.3'
  s.summary          = 'Flutter plugin for monitoring system clipboard on Android and iOS.'
  s.description      = <<-DESC
Flutter plugin for monitoring system clipboard changes on Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/mix1009/flutter_clipboard_monitor'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mix1009' => 'mix1009@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
