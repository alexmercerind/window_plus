#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint window_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'window_plus'
  s.version          = '0.0.1'
  s.summary          = 'window_plus'
  s.description      = <<-DESC
window_plus
                       DESC
  s.homepage         = 'https://github.com/alexmercerind/window_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hitesh Kumar Saini' => 'saini123hitesh@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
