#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint eidmsdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'eidmsdk'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
eIDmSDK wrapper for Flutter
                       DESC
  s.homepage         = 'https://www.freevision.sk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ahmed Al Hafoudh' => 'alhafoudh@freevision.sk' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.vendored_frameworks = 'Frameworks/eID.framework'
  s.dependency 'OpenSSL-Universal'
  s.dependency 'JWTDecode'
  s.dependency 'lottie-ios'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
