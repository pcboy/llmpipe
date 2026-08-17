# frozen_string_literal: true

require 'yaml'
require 'json'
require 'ruby_llm'
require_relative 'cache'
require_relative 'config'

module Llmp
  class Pipe
    REQUIRED_FIELDS = %w[provider model system_prompt].freeze
    attr_reader :config, :yaml_content

    def initialize(yaml_path, args: [], cache: nil)
      @yaml_path = yaml_path
      @args = args
      @yaml_content = File.read(yaml_path)
      @config = YAML.safe_load(substitute_args(@yaml_content))

      missing = REQUIRED_FIELDS.reject { |f| @config.key?(f) }
      raise "Missing required fields: #{missing.join(', ')}" unless missing.empty?

      @cache = cache || Cache.new
      @input_data = nil
    end

    def execute(input_data, force: false)
      @input_data = input_data

      configure

      @cache.fetch(@yaml_content, @input_data, force: force) do
        call_llm
      end
    end

    private

    def substitute_args(content)
      return content if @args.empty?

      result = content

      # Replace $* with all arguments joined by space (YAML-escaped)
      result = result.gsub('$*', escape_yaml_value(@args.join(' ')))

      # Replace $1, $2, $3, etc. with corresponding arguments (YAML-escaped)
      @args.each_with_index do |arg, index|
        result = result.gsub("$#{index + 1}", escape_yaml_value(arg))
      end

      result
    end

    def escape_yaml_value(value)
      YAML.dump(value).gsub(/^--- /, '').strip
    end

    def configure
      user_config = Config.load

      RubyLLM.configure do |config|
        user_config.each do |key, value|
          config.send("#{key}=", value) if config.respond_to?("#{key}=")
        end
      end
    end

    def call_llm
      provider = @config['provider']
      model = @config['model']
      temperature = @config['temperature'] || 0.6
      system_prompt = @config['system_prompt']

      chat = RubyLLM.chat(model: model, provider: provider, assume_model_exists: true)
      chat.with_temperature(temperature)
      chat.with_instructions(system_prompt)
      response = chat.ask(@input_data)

      response.content
    end
  end
end
