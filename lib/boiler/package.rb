require 'boiler/helpers'

module Boiler
  class Package
    include Boiler::Helpers
    include Thor::Actions

    attr_accessor :config
    attr_accessor :package_name
    attr_accessor :tmp

    def initialize(dir)
      @src          = File.expand_path dir
      @config       = merge_defaults_with_manifest
      @package_name = target_file_name
      @tmp      = "#{tmp_boiler}/#{@package_name}"
    end

    def copy_files_to_tmp
      # Collect paths that aren't a directory or in ignore
      paths = Dir.glob("#{@src}/**/*")
      paths.reject! do |path|
        File.directory? path or
        @config[:ignore].include? File.basename(path)
      end

      # Make sure we have a place to copy to
      FileUtils.mkdir_p(@tmp)

      # Copy each file to tmp
      paths.each do |path|
        dir, name = File.dirname(path), File.basename(path)
        target = dir.gsub(@src, @tmp)

        FileUtils.mkdir_p target
        FileUtils.cp_r path, "#{target}/#{name}"
      end
    end

    private

    def merge_defaults_with_manifest
      package_manifest = load_manifest
      d = defaults(package_manifest[:name])
      d.deep_merge!(package_manifest)
    end

    def load_manifest
      JSON.parse(File.read(manifest(@src)), {
        :symbolize_names => true
      })
    end

    def defaults(name)
      {
        name: name,
        version: '0.0.0',
        description: "",
        authors: [],
        dependencies: {},
        license: 'MIT',
        arch: 'noarch',
        build: 'unraid',
        prefix: {
          :"usr/local/boiler/#{to_simple_param name}" => [
              'bin',
              'lib',
              'Gemfile*'
          ],
          :"#{configs(name)}" => [
            'config/*'
          ],
          :"usr/docs/#{to_simple_param name}" => [
            'README.*',
            'LICENSE*'
          ],
          :"var/log/boiler/#{to_simple_param name}" => [
            'boiler.json'
          ]
        },
        ignore: [],
        symlink: {},
        post_install: []
      }
    end

    def configs(name)
      "/boot/plugins/custom/#{to_simple_param name}/_config"
    end

    def target_file_name
      @target_file_name ||= [
        @config[:name],
        @config[:version],
        @config[:arch],
        @config[:build]
      ].join('-')
    end
  end
end
