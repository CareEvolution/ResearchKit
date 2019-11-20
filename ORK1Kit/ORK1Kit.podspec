Pod::Spec.new do |s|
  s.name         = 'ORK1Kit'
  s.version      = '1.5.2'
  s.summary      = 'ORK1Kit is an open source software framework that makes it easy to create apps for medical research or for other research projects.'
  s.homepage     = 'https://www.github.com/ORK1Kit/ORK1Kit'
  s.documentation_url = 'http://researchkit.github.io/docs/'
  s.license      = { :type => 'BSD', :file => 'LICENSE' }
  s.author       = { 'researchkit.org' => 'http://researchkit.org' }
  s.source       = { :git => 'https://github.com/ORK1Kit/ORK1Kit.git', :tag => s.version.to_s }
  s.public_header_files = `./scripts/find_headers.rb --public --private`.split("\n")
  s.source_files = 'ORK1Kit/**/*.{h,m,swift}'
  s.resources    = 'ORK1Kit/**/*.{fsh,vsh}', 'ORK1Kit/Animations/**/*.m4v', 'ORK1Kit/Artwork.xcassets', 'ORK1Kit/Localized/*.lproj'
  s.platform     = :ios, '8.2'
  s.requires_arc = true
end
