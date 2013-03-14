# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shellex/version'

Gem::Specification.new do |spec|
  spec.name          = "shellex"
  spec.version       = Shellex::VERSION
  spec.authors       = ["Dima Sabanin"]
  spec.email         = ["sdmitry@gmail.com"]
  spec.description   = %q{Shell execution made easy and secure}
  spec.summary       = %q{Allows you to securely execute shell code with exceptions on errors and timeouts}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
