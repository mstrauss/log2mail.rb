# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'log2mail/version'

Gem::Specification.new do |spec|
  spec.name          = 'log2mail'
  spec.version       = Log2mail::VERSION
  spec.authors       = Log2mail::AUTHOR
  spec.email         = Log2mail::AUTHOR_MAIL
  spec.summary       = %q{monitors (log) files for patterns and reports hits by mail}
  spec.description   = %q{A regular expression based log file monitoring tool.}
  spec.homepage      = 'https://github.com/mstrauss/ruby-log2mail/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.extra_rdoc_files = Dir.glob('man/*.html')

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'ronn'
  spec.add_development_dependency 'cucumber'
  spec.add_development_dependency 'rake-notes'
  spec.add_runtime_dependency 'mail', '~> 2.6', '>= 2.6.3'
  spec.add_runtime_dependency 'gem-man', '~> 0.3', '>= 0.3.0'
  spec.add_runtime_dependency 'main', '~> 6.1.0'
  spec.add_runtime_dependency 'terminal-table'
end
