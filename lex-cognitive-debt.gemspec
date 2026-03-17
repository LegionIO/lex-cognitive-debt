# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_debt/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-debt'
  spec.version       = Legion::Extensions::CognitiveDebt::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Debt'
  spec.description   = 'Cognitive debt modeling for brain-modeled agentic AI — deferred processing that accrues interest over time'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-debt'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-cognitive-debt'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-cognitive-debt'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-cognitive-debt'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-cognitive-debt/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-debt.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
