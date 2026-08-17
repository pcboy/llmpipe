# frozen_string_literal: true

require 'optimist'
require 'fileutils'
require 'runcom'

module Llmp
  class Cli
    def self.parse(argv = ARGV)
      opts = build_options(argv)

      positional = argv.reject { |arg| arg.start_with?('-') }
      if positional.empty? || opts[:help]
        build_options(['--help'])
        exit 1
      end

      opts[:pipe] = positional.first
      opts[:pipe_path] = resolve_pipe_path(positional.first)
      opts[:args] = positional.drop(1)

      opts
    end

    def self.build_options(argv)
      Optimist.options(argv) do
        version 'Llmp v0.1.0'
        banner <<~BANNER

          Usage: llmp <pipe_name_or_path> [args...] [options]

          A Ruby-based CLI framework for composable LLM workflows using Unix pipe philosophy.

          Pipe arguments are available in prompts as $1, $2, $3, etc. and $* for all arguments.

          Examples:
            llmp summarize < url.txt
            llmp ./pipes/custom.yml < url.txt
            llmp translate -f < data.txt
            llmp review ruby -- -Wno-unused-variable < code.rb
        BANNER

        opt :force, 'Bypass cache and force LLM call', type: :boolean, default: nil, short: 'f'
        opt :help, 'Show this message', type: :boolean, default: nil, short: 'h'
      end
    end

    def self.resolve_pipe_path(pipe_arg)
      return pipe_arg if pipe_arg.include?('/') || pipe_arg.end_with?('.yml', '.yaml')

      paths_to_try = [
        cwd_path(pipe_arg),
        env_var_path(pipe_arg),
        global_path(pipe_arg)
      ].compact

      paths_to_try.each do |path|
        return path if File.exist?(path)
      end

      nil
    end

    def self.cwd_path(pipe_arg)
      base_name = pipe_arg.end_with?('.yml', '.yaml') ? pipe_arg : "#{pipe_arg}.yml"
      File.expand_path(base_name)
    end

    def self.env_var_path(pipe_arg)
      env_path = ENV['LLMP_PIPES_PATH']
      return nil if env_path.nil? || env_path.empty?

      base_name = pipe_arg.end_with?('.yml', '.yaml') ? pipe_arg : "#{pipe_arg}.yml"
      File.expand_path(base_name, env_path)
    end

    def self.global_path(pipe_arg)
      config = Runcom::Config.new("llmp/pipes/#{pipe_arg}")
      base_name = pipe_arg.end_with?('.yml', '.yaml') ? pipe_arg : "#{pipe_arg}.yml"
      config_path = config.active || config.passive
      File.join(File.dirname(config_path.to_s), base_name)
    end
  end
end
