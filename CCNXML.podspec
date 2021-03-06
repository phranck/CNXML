Pod::Spec.new do |s|
  s.name                  = 'CCNXML'
  s.version               = '0.2.3'
  s.summary               = 'Simple basic handling of XML files for both reading and manual creation.'
  s.homepage              = 'https://github.com/phranck/CCNXML'
  s.author                = { 'Frank Gregor' => 'phranck@cocoanaut.com' }
  s.source                = { :git => 'https://github.com/phranck/CCNXML.git', :tag => s.version.to_s }
  s.osx.deployment_target = '10.7'
  s.ios.deployment_target = '6.0'
  s.requires_arc          = true
  s.source_files          = '*.{h,m}'
  s.license               = { :type => 'MIT', :file => 'ReadMe.md' }
end
