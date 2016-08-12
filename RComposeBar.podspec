Pod::Spec.new do |s|
s.name             = 'RComposeBar'
s.version          = '1.0.1'
s.summary          = 'Compose bar view suitable for chat applications'
s.description    = <<-DESC
Userfriendly compose bar implemention to use in chat/im applications.
It is configurable to resize with text and other usable inputs like images/videos/location etc.
Heights and other relavant UIs will be configure based on user/developer inputs and most of the visible fetures are customizable.
DESC

s.homepage         = 'https://github.com/rjeprasad/RComposeBar'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'Rajeev Prasad' => 'rjeprasad@gmail.com' }
s.source           = { :git => 'https://github.com/rjeprasad/RComposeBar.git', :tag => s.version.to_s }
s.source_files = 'RComposeBar/Classes/*'
s.preserve_paths = 'LICENSE', 'README.md'
s.requires_arc   = true
s.ios.deployment_target = '8.3'
s.platform       = :ios

end
