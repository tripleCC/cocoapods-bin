# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-bin/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-bin'
  spec.version       = CBin::VERSION
  spec.authors       = ['tripleCC']
  spec.email         = ['triplec.linux@gmail.com']
  spec.description   = %q{cocoapods-bin.}
  spec.summary       = %q{cocoapods-bin.}
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
