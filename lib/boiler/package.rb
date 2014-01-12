require 'boiler/helpers'

module Boiler
  class Package
    include Boiler::Helpers
    include Thor::Actions

    attr_accessor :config
    attr_accessor :package_name
    attr_accessor :tmp

    def initialize(dir)
      @src           = File.expand_path dir
      @config        = merge_defaults_with_manifest
      @name_to_param = to_simple_param @config[:name]
      @package_name  = target_file_name
      @tmp           = "#{tmp_boiler}/#{@package_name}"
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

    def map_dependencies_with_trolley
      if config[:dependencies]
        config[:dependencies].map do |pkg, version|
          if /^http/ =~ version
            "trolley install #{version}"
          else
            "trolley install #{pkg} #{version}"
          end
        end
      end
    end

    def map_symlinks
      bins = Dir.glob "#{@tmp}/bin/*"

      if bins.any?
        bin_map = bins.map { |bin|
          bin_name = File.basename bin
          { :"/#{bin_path}/#{bin_name}" => "/usr/local/bin/#{bin_name}" }
        }

        config[:symlink].merge! bin_map.first
      end

      config[:symlink].map { |src, dest|
        "ln -sf #{src} #{dest}"
      }
    end

    def preserve_config_cmds
      cmds = []
      target_config_path = configs_path.gsub('_config', 'config')

      # Copy config files if they don't exist
      # Must be bash to be installable with installpkg
      cmds << <<-CMD.gsub(/^ {8}/, '')
        if [ ! -f /#{target_config_path} ]; then
          cp -r /#{configs_path} /#{target_config_path}
        fi
      CMD

      # Remove the original _config directory regardless
      cmds << "rm -rf /#{configs_path}\n"
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
          :"#{bin_path}" => [
              'bin',
              'lib',
              'Gemfile*'
          ],
          :"#{configs_path}" => [
            'config/*'
          ],
          :"#{docs_path}" => [
            'README.*',
            'LICENSE*'
          ],
          :"#{manifest_path}" => [
            'boiler.json'
          ]
        },
        ignore: [],
        symlink: {},
        post_install: []
      }
    end

    def bin_path
      "usr/local/boiler/#{@name_to_param}"
    end

    def docs_path
      "usr/docs/#{@name_to_param}"
    end

    def configs_path
      "boot/plugins/custom/#{@name_to_param}/_config"
    end

    def manifest_path
      "var/log/boiler/#{@name_to_param}"
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
