#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint eidmsdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'eidmsdk'
  s.version          = '1.0.0'
  s.summary          = 'eID mSDK Flutter'
  s.description      = 'eID mSDK wrapper for Flutter'
  s.homepage         = 'https://www.freevision.sk'
  s.license          = { :file => '../LICENSE' }
  s.author           = {
                          'Ahmed Al Hafoudh' => 'alhafoudh@freevision.sk',
                          'Matej Hlatky' => 'hlatky@freevision.sk'
                       }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.vendored_frameworks = 'Frameworks/eID.xcframework'
  s.dependency 'OpenSSL-Universal'
  s.dependency 'JWTDecode'
  s.dependency 'lottie-ios'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
