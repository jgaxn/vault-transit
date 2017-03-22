# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vault/transit/version'

Gem::Specification.new do |spec|
  spec.name          = "vault-transit"
  spec.version       = Vault::Transit::VERSION
  spec.authors       = ["John Atkinson"]
  spec.email         = ["jgaxn0@gmail.com"]

  spec.summary       = "Ruby API client for interacting with the Vault Transit secret backend"
  spec.homepage      = "https://github.com/jgaxn/vault-transit"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "vault", "~> 0.8"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
