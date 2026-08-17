# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/llmp/cli'

RSpec.describe Llmp::Cli do
  let(:tmpdir) { Dir.mktmpdir }
  let(:original_home) { ENV['HOME'] }
  let(:original_env_path) { ENV['LLMP_PIPES_PATH'] }

  before do
    ENV['HOME'] = tmpdir
    ENV['LLMP_PIPES_PATH'] = nil
  end

  after do
    ENV['HOME'] = original_home
    ENV['LLMP_PIPES_PATH'] = original_env_path
  end

  def create_pipe_file(filename, content, dir = tmpdir)
    path = File.join(dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe '.parse' do
    it 'shows help when no args' do
      expect { described_class.parse([]) }.to raise_error(SystemExit)
    end

    it 'shows help when --help flag' do
      expect { described_class.parse(['--help']) }.to raise_error(SystemExit)
    end

    it 'sets pipe argument' do
      opts = described_class.parse(['summarize'])
      expect(opts[:pipe]).to eq('summarize')
    end

    it 'captures positional arguments after pipe name' do
      opts = described_class.parse(%w[review ruby performance])
      expect(opts[:pipe]).to eq('review')
      expect(opts[:args]).to eq(%w[ruby performance])
    end
  end

  describe '.resolve_pipe_path' do
    it 'returns direct path with slash' do
      pipe_file = create_pipe_file('custom.yml', 'name: test')
      result = described_class.resolve_pipe_path(pipe_file)
      expect(result).to eq(pipe_file)
    end

    it 'returns direct path with yaml extension' do
      pipe_file = create_pipe_file('test.yml', 'name: test')
      result = described_class.resolve_pipe_path(pipe_file)
      expect(result).to eq(pipe_file)
    end

    it 'finds file in current directory' do
      create_pipe_file('summarize.yml', 'name: summarize')
      Dir.chdir(tmpdir) do
        result = described_class.resolve_pipe_path('summarize')
        expect(result).to eq(File.join(tmpdir, 'summarize.yml'))
      end
    end

    it 'finds file via env var path' do
      pipes_dir = File.join(tmpdir, 'pipes')
      FileUtils.mkdir_p(pipes_dir)
      ENV['LLMP_PIPES_PATH'] = pipes_dir
      create_pipe_file('translate.yml', 'name: translate', pipes_dir)

      result = described_class.resolve_pipe_path('translate')
      expect(result).to eq(File.join(pipes_dir, 'translate.yml'))
    end

    it 'returns nil when not found' do
      result = described_class.resolve_pipe_path('nonexistent_pipe')
      expect(result).to be_nil
    end
  end
end
