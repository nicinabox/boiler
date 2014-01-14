require 'boiler/base'
require 'git'

module Boiler
  class Repo < Base

    attr_accessor :name, :url, :version, :dest, :base

    def initialize(url, name=nil, version=nil)
      set_name_and_url(name, url)

      @version = version
      @dest    = tmp_repo

      reset_dir
    end

    def clone
      @base = Git.clone(url, name, :path => tmp_boiler_path)
    end

    def release
      return if base.nil?

      @version ||= all_tags.last
      base.checkout version
      version
    end

    def convert_to_git_protocol(url)
      git_url = url.gsub(/(git@|https:\/\/)/, 'git://')
      git_url if git_protocol? git_url
    end

  private

    def set_name_and_url(name, url)
      if name
        @name = name
        @url  = url
      else
        @name = File.basename(url).gsub(/\.git$/, '')
        @url  = url
      end
    end

    def all_tags
      base.lib.tags.sort { |x, y|
        Gem::Version.new(x) <=> Gem::Version.new(y)
      }
    end

    def reset_dir
      cleanup dest
      FileUtils.mkdir_p tmp_boiler_path
    end

    def git_protocol?(url)
      true if /^git:\/\// =~ url
    end

    def public_repo?(url)
      true if `git ls-remote #{url}`.include? 'master'
    end

    def tmp_repo
      "#{tmp_boiler_path}/#{name}"
    end

  end
end
