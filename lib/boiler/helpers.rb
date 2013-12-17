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
      repo = nil

      # Remove that directory before we create it
      FileUtils.rm_rf dest

      Dir.chdir("/tmp/boiler") do
        `git clone --quiet -- #{url} #{name}`
        repo = Rugged::Repository.new(dest)

        tags = repo.tags.map { |t| t }
        tags.sort! {|x, y| Gem::Version.new(x) <=> Gem::Version.new(y) }

        version = tags.last unless version
        `cd #{name} && git checkout --quiet #{version}`
      end

      {
        repo: repo,
        version: version
      }
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
  end
end
