# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'runcom'

module Llmp
  class Config
    def self.load(path: nil)
      if path
        config_path = path
      else
        config = Runcom::Config.new('llmp/config.yml')
        config_path = config.active || config.passive
      end

      return {} unless config_path
      return {} unless File.exist?(config_path)

      YAML.safe_load(File.read(config_path.to_s)) || {}
    rescue Psych::SyntaxError => e
      warn "Warning: Invalid YAML in #{config_path}: #{e.message}"
      {}
    end
  end
end
