#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_arcface_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  # 表示libstdc++.6.0.9.tdb,省略lib前缀，省略.tbd后缀
  s.libraries = 'stdc++.6.0.9'
  s.ios.vendored_frameworks = 'Frameworks/ArcSoftFaceEngine.framework'
  # s.vendored_frameworks = 'ArcSoftFaceEngine.framework'
  #s.resources = ['Resource/libstdc++.6.0.9.tbd', 'Resource/ic_action_back_light@3x.png', 'Resource/ic_action_back_light@2x.png', 'Resource/ic_action_back_light.png']
  s.resources = 'Resource/*'
  s.ios.deployment_target = '8.0'
end

