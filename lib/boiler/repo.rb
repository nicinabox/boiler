require 'boiler/base'
require 'boiler/manifest'
require 'git'

module Boiler
  class Repo < Base

    attr_accessor :name, :url, :version, :path, :base,
                  :manifest

    def initialize(url, name=nil, version=nil)
      set_name_and_url(name, url)

      @version  = parse_version(version)
      @path     = tmp_repo
      @manifest = Manifest.new path, name
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

    def validate
      unless convert_to_git_protocol
        return 'Url must use git:// protocol'
      end

      unless public_repo?
        return 'Package must be a public repo'
      end

      clone

      unless manifest.exists?
        return 'Package is missing boiler.json'
      end

      metadata = manifest.to_json
      manifest.required.each do |key, val|
        unless metadata.has_key? key and metadata[key].empty?
          return "boiler.json requires #{key}"
        end
      end
    end

    def convert_to_git_protocol
      git_url = url.gsub(/(git@|https:\/\/)/, 'git://')
      url = git_url if git_protocol? git_url
    end

  private

    def parse_version(version)
      if /head|latest|master/i =~ version
        'master'
      else
        version
      end
    end

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
      base.lib.tags
    end

    def reset_dir
      cleanup path
      FileUtils.mkdir_p tmp_boiler_path
    end

    def git_protocol?(url)
      true if /^git:\/\// =~ url
    end

    def public_repo?
      `git ls-remote #{url}`.include? 'master'
    end

    def tmp_repo
      "#{tmp_boiler_path}/#{name}"
    end

  end
end
