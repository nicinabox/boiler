require 'grit'
require 'httparty'
require 'fileutils'

module Gat
  module Helpers
    include Grit

    def pretty_print(args)
      puts "%-20s %10s" % args
    end

    def status(message, color = nil)
      say "=> #{message}", color
    end

    def tmp_repo(name)
      "/tmp/gat/#{name}"
    end

    def clone_repo(name, url)
      dest = tmp_repo(name)

      repo = Git.new(dest)
      repo.clone({ :quiet => true }, url, dest)
      dest
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
      "#{dest}/gat.json"
    end

    def cleanup(dest)
      FileUtils.rm_rf dest
    end

    def url?(url)
      HTTParty.get(url).code == 200 rescue nil
    end
  end
end
