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
  end
end
