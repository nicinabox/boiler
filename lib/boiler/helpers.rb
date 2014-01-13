require 'httparty'
require 'fileutils'
require 'deep_merge'
require 'crack'

module Boiler
  module Helpers

    def status(message, color = nil)
      say "=> #{message}", color
    end

    def to_simple_param(string)
      string.downcase.gsub(' ', '-')
    end

    def tmp_boiler
      "/tmp/boiler"
    end

    def tmp_repo(name)
      "#{tmp_boiler}/#{name}"
    end

    def required
      %w(name version)
    end

    def installed_packages(name)
      wildcard = name ? "#{name}*" : "**"
      Dir.glob("/var/log/boiler/#{wildcard}/boiler.json")
    end

    def manifest(dest)
      "#{dest}/boiler.json"
    end

    def cleanup(dest)
      FileUtils.rm_rf dest
    end

    def url?(url)
      HTTParty.get(url).code == 200 rescue nil
    end

    def name_and_email
      "#{git_config('user.name')} <#{git_config('user.email')}>"
    end

    def git_config(key)
      Git.global_config(key)
    end

    def default(*vals)
      vals.each do |val|
        return val unless (val.nil? or val.empty?)
      end
    end

    def manifest_wizard(config = {})
      config[:name]        = ask "name:", default: default(config[:name], File.basename(Dir.pwd))
      config[:version]     = ask "version:", default: default(config[:version], '0.1.0')
      config[:authors]     = ask "authors:", default: default(config[:authors], name_and_email)
      config[:description] = ask "description:", default: config[:description]
      config[:homepage]    = ask "homepage:", default: config[:homepage]
      config[:license]     = ask "license:", default: default(config[:license], 'MIT')

      config
    end
  end
end
