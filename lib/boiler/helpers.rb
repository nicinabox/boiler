require 'git'
require 'httparty'
require 'fileutils'
require 'deep_merge'

module Boiler
  module Helpers
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

      g = Git.clone(url, name, :path => path)
      tags = g.lib.tags.sort {|x, y| Gem::Version.new(x) <=> Gem::Version.new(y) }
      version = tags.last unless version
      g.checkout version
      g

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
  end
end
