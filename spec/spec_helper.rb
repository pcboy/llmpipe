# frozen_string_literal: true

require 'rspec'
require 'tmpdir'
require 'fileutils'
require 'delegate'
require 'ruby_llm'
require 'ruby_llm/test'

require_relative '../lib/llmp/pipe'
require_relative '../lib/llmp/cache'

RubyLLM::Models.singleton_class.prepend(RubyLLM::Test::ResolveWithTestProvider)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:each) do
    RubyLLM::Test.reset
    RubyLLM.configure do |c|
      c.openai_api_key = 'test_key'
      c.anthropic_api_key = 'test_key'
    end
  end
end
