#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint media_and_create_date_picker.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'media_and_create_date_picker'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin that picture and video gallery items and get item create date.'
  s.description      = <<-DESC
A Flutter plugin that picture and video gallery items and get item create date.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
