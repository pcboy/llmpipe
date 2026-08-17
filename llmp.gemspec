# frozen_string_literal: true

require_relative 'lib/llmp/version'

Gem::Specification.new do |spec|
  spec.name          = 'llmp'
  spec.version       = Llmp::VERSION
  spec.authors       = ['David Hagege']
  spec.email         = ['david@joynetiks.com']

  spec.summary       = 'A Ruby-based CLI for composable LLM workflows'
  spec.description   = <<~EOL
    Build composable LLM workflows using Unix pipe philosophy.
    Each pipe is a YAML-configured LLM call that communicates via stdin/stdout.
  EOL
  spec.homepage      = 'https://github.com/pcboy/llmpipe'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.glob('lib/**/*') + Dir.glob('bin/*') + %w[README.md llmp.gemspec]

  spec.bindir        = 'bin'
  spec.executables   = ['llmp']
  spec.require_paths = ['lib']

  spec.add_dependency 'json', '~> 2.0'
  spec.add_dependency 'optimist', '~> 3.0'
  spec.add_dependency 'ruby_llm', '~> 1.16'
  spec.add_dependency 'runcom', '~> 12.3'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'ruby_llm-test', '~> 0.2'
end
