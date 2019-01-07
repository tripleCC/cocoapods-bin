# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-bin/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-bin'
  spec.version       = CBin::VERSION
  spec.authors       = ['tripleCC']
  spec.email         = ['triplec.linux@gmail.com']
  spec.description   = %q{组件二进制化插件.}
  spec.summary       = %q{组件二进制化插件。利用源码私有源与二进制私有源实现对组件依赖类型的切换.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-bin'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'parallel'
  spec.add_dependency 'cocoapods', '~> 1.2'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
