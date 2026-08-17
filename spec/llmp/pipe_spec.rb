# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llmp::Pipe do
  let(:tmpdir) { Dir.mktmpdir }
  let(:pipes_dir) { File.join(tmpdir, 'pipes') }
  let(:cache) { Llmp::Cache.new }

  before do
    FileUtils.mkdir_p(pipes_dir)
  end

  def create_pipe_file(filename, content)
    path = File.join(pipes_dir, filename)
    File.write(path, content)
    path
  end

  describe '#config' do
    it 'parses YAML configuration correctly' do
      yaml_path = create_pipe_file('test_pipe.yml', <<~YAML)
        name: test_pipe
        provider: openai
        model: gpt-4
        temperature: 0.5
        system_prompt: You are a helpful assistant.
      YAML

      pipe = Llmp::Pipe.new(yaml_path, cache: cache)

      expect(pipe.config['name']).to eq('test_pipe')
      expect(pipe.config['provider']).to eq('openai')
      expect(pipe.config['model']).to eq('gpt-4')
      expect(pipe.config['temperature']).to eq(0.5)
      expect(pipe.config['system_prompt']).to eq('You are a helpful assistant.')
    end
  end

  describe '#yaml_content' do
    it 'stores the raw YAML content' do
      yaml_content = <<~YAML
        name: test_pipe
        provider: anthropic
        model: claude-3-5-sonnet
        temperature: 0.2
        system_prompt: Summarize the text.
      YAML

      yaml_path = create_pipe_file('test.yml', yaml_content)
      pipe = Llmp::Pipe.new(yaml_path, cache: cache)

      expect(pipe.yaml_content).to eq(yaml_content)
    end
  end

  describe '#execute' do
    it 'raises error for unsupported provider' do
      yaml_path = create_pipe_file('bad_provider.yml', <<~YAML)
        name: bad_pipe
        provider: unsupported_provider
        model: some-model
        system_prompt: Test prompt.
      YAML

      pipe = Llmp::Pipe.new(yaml_path, cache: cache)

      expect { pipe.execute('test input') }.to raise_error(RubyLLM::Error, /Unknown provider|unsupported_provider/i)
    end

    it 'executes and caches result' do
      yaml_path = create_pipe_file('test_pipe.yml', <<~YAML)
        name: test_pipe
        provider: openai
        model: gpt-4
        temperature: 0.7
        system_prompt: Echo back the input.
      YAML

      pipe = Llmp::Pipe.new(yaml_path, cache: cache)
      input_data = 'Hello, world!'
      expected_output = 'Mocked response from OpenAI'

      RubyLLM::Test.with_responses(expected_output) do
        result = pipe.execute(input_data)
        expect(result).to eq(expected_output)
      end

      expect(File.exist?(cache.cache_path(cache.key_for(pipe.yaml_content, input_data)))).to be true
    end

    it 'bypasses cache with force: true' do
      yaml_path = create_pipe_file('force_test.yml', <<~YAML)
        name: force_test
        provider: openai
        model: gpt-4
        temperature: 0.5
        system_prompt: Test.
      YAML

      pipe = Llmp::Pipe.new(yaml_path, cache: cache)
      input_data = 'test input'

      RubyLLM::Test.with_responses('First call', 'Second call (forced)') do
        first_result = pipe.execute(input_data)
        expect(first_result).to eq('First call')
        expect(File.exist?(cache.cache_path(cache.key_for(pipe.yaml_content, input_data)))).to be true

        second_result = pipe.execute(input_data, force: true)
        expect(second_result).to eq('Second call (forced)')
      end
    end
  end

  describe 'cache key generation' do
    it 'generates different cache keys when YAML content changes' do
      original_yaml = <<~YAML
        name: test_pipe
        provider: openai
        system_prompt: Original prompt.
      YAML

      modified_yaml = <<~YAML
        name: test_pipe
        provider: openai
        system_prompt: Modified prompt.
      YAML

      key1 = cache.key_for(original_yaml, 'test input')
      key2 = cache.key_for(modified_yaml, 'test input')

      expect(key1).not_to eq(key2)
    end

    it 'generates different cache keys when input changes' do
      yaml = <<~YAML
        name: test_pipe
        provider: openai
        system_prompt: Test prompt.
      YAML

      key1 = cache.key_for(yaml, 'first input')
      key2 = cache.key_for(yaml, 'second input')

      expect(key1).not_to eq(key2)
    end
  end

  describe 'argument substitution' do
    it 'substitutes $1, $2, $3 in system_prompt' do
      yaml_content = <<~YAML
        name: test_args
        provider: openai
        model: gpt-4
        system_prompt: Greet $1 who is learning $2 in $3
      YAML

      yaml_path = create_pipe_file('args_test.yml', yaml_content)
      pipe = Llmp::Pipe.new(yaml_path, args: %w[Alice Ruby English], cache: cache)

      expect(pipe.config['system_prompt']).to eq('Greet Alice who is learning Ruby in English')
    end

    it 'substitutes $* with all arguments joined' do
      yaml_content = <<~YAML
        name: test_args
        provider: openai
        model: gpt-4
        system_prompt: |
          Process these arguments: $*
      YAML

      yaml_path = create_pipe_file('args_all_test.yml', yaml_content)
      pipe = Llmp::Pipe.new(yaml_path, args: ['hello', 'world', 'foo bar'], cache: cache)

      expect(pipe.config['system_prompt'].strip).to eq('Process these arguments: hello world foo bar')
    end
  end
end
