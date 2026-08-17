# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'runcom'

module Llmp
  class Cache
    def initialize
      @cache = Runcom::Cache.new('llmp')
      @cache_dir = @cache.passive.to_s
      FileUtils.mkdir_p(@cache_dir)
    end

    def key_for(yaml_content, input_data)
      Digest::SHA256.hexdigest(yaml_content + input_data)
    end

    def cache_path(key)
      File.join(@cache_dir, "#{key}.json")
    end

    def lock_path(key)
      File.join(@cache_dir, "#{key}.lock")
    end

    def fetch(yaml_content, input_data, force: false)
      key = key_for(yaml_content, input_data)
      path = cache_path(key)
      lock_file = lock_path(key)

      File.open(lock_file, File::CREAT | File::RDWR) do |lf|
        lf.flock(File::LOCK_EX)

        # Check cache only if not forced
        if !force && File.exist?(path)
          cached = JSON.parse(File.read(path), symbolize_names: true)
          return cached[:output]
        end

        # Cache miss or forced - compute and store atomically
        output = yield
        File.write(path, JSON.pretty_generate({ output: }))
        output
      end
    end
  end
end
