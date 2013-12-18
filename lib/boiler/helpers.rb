require 'git'
require 'httparty'
require 'fileutils'
require 'deep_merge'

module Boiler
  module Helpers

    def two_columns(*args)
      puts "%-15s %s" % args
    end

    def three_columns(*args)
      puts "%-15s %-15s %s" % args
    end

    def status(message, color = nil)
      say "=> #{message}", color
    end

    def unraid?
      /unraid/i =~ `uname -a`.strip
    end

    def tmp_repo(name)
      "/tmp/boiler/#{name}"
    end

    def clone_repo(name, url, version=nil)
      dest = tmp_repo(name)
      path = "/tmp/boiler"

      # Remove that directory before we create it
      FileUtils.rm_rf dest
      FileUtils.mkdir_p path

      repo = Git.clone(url, name, :path => path)
      tags = repo.lib.tags.sort {|x, y| Gem::Version.new(x) <=> Gem::Version.new(y) }
      repo.checkout (version ||= tags.last)
      [repo, version]
    end

    def public_repo?(url)
      true if `git ls-remote #{url}`.include? 'master'
    end

    def git_protocol?(url)
      true if /^git:\/\// =~ url
    end

    def manifest_exists?(dest)
      true if File.exists? manifest(dest)
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
        return val unless (val.empty? or val.nil?)
      end
    end

    def manifest_wizard(config = {})
      config[:name] = ask "name:", default: default(config[:name], File.basename(Dir.pwd))
      config[:version]     = ask "version:", default: default(config[:version], '0.1.0')
      config[:authors]     = ask "authors:", default: default(config[:authors], name_and_email)
      config[:description] = ask "description:", default: config[:description]
      config[:homepage]    = ask "homepage:", default: config[:homepage]
      config[:license]     = ask "license:", default: config[:license]

      config
    end

    def extract_dependency(f)
      if /tx|jz$/ =~ f['URL']
        f['URL']
      end
    end

    def extract_asset(f)
      {
        :dest => f['Name'],
        :url  => f['URL']
      }
    end

  end
end
