require 'boiler/base'
require 'boiler/manifest'

module Boiler
  class Package < Base
    include Thor::Base
    include Thor::Actions
    source_root Dir.pwd

    attr_accessor :config, :tmp, :src, :name_to_param,
                  :manifest, :package_path

    def initialize(dir)
      @src              = File.expand_path dir
      @manifest         = Manifest.new src
      @config           = merge_defaults_with_manifest
      @tmp              = "#{tmp_boiler_path}/#{abridged_file_name}"

      @name_to_param    = to_simple_param manifest.name

      # For Thor
      @options           = {}
      @destination_stack = [tmp]
    end

    def build
      copy_files_to_tmp
      setup_env
      setup_post_install
      run_tasks
      prefix_files
      archive
      move_package_to_cwd
      cleanup tmp

      file_name
    end

    def copy_files_to_tmp
      # Collect paths that aren't a directory or in ignore
      paths = Dir.glob("#{src}/**/*")
      paths.reject! do |path|
        File.directory? path or
        map_ignores.index { |p| path.include? p }
      end

      # Make sure we have a place to copy to
      FileUtils.mkdir_p tmp

      # Copy each file to tmp
      paths.each do |path|
        dir, name = File.dirname(path), File.basename(path)
        target = dir.gsub(src, tmp)

        FileUtils.mkdir_p target
        FileUtils.cp_r path, "#{target}/#{name}"
      end
    end

    def map_ignores
      @map_ignores ||= config[:ignore].map { |path|
        File.expand_path "#{src}/#{path}"
      }
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
      bins = Dir.glob "#{tmp}/bin/*"
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

    def map_preserve_config_cmds
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
      cmds << "rm -rf /#{configs_path}"
    end

    def map_env_vars
      name              = config[:name].upcase.gsub(/\-/, '_')
      target_config_dir = configs_path.gsub('_config', 'config')

      [
        "#{name}_CONFIG_PATH=/#{target_config_dir}"
      ]
    end

    def setup_post_install
      # Make sure we have a file
      doinst = "install/doinst.sh"
      unless File.exists? "#{tmp}/#{doinst}"
        create_file doinst, verbose: false
      end

      # Collect everything to inject
      config[:post_install].unshift map_symlinks
      config[:post_install].unshift map_preserve_config_cmds
      config[:post_install].flatten!

      prepend_to_file doinst, verbose: false do
        install_trolley +
        map_dependencies_with_trolley.join("\n") + "\n"
      end

      append_to_file doinst, verbose: false do
        config[:post_install].join("\n") + "\n"
      end
    end

    def setup_env
      create_file env_path, verbose: false
      append_to_file env_path, verbose: false do
        map_env_vars.join("\n")
      end
    end

    def run_tasks
      config[:tasks].each do |task|
        status "Running #{task}"
        `#{task}`
      end
    end

    def prefix_files
      config[:prefix].each do |prefix, srcs|
        dest = "#{tmp}/#{prefix}"
        FileUtils.mkdir_p dest
        srcs.each do |src|
          fullpath = "#{tmp}/#{src}"
          FileUtils.mv Dir.glob(fullpath), dest
        end
      end
    end

    def archive
      Dir.chdir tmp do
        if unraid?
          `makepkg -c y #{tmp_boiler_path}/#{file_name}`
        else
          `tar -czf #{tmp_boiler_path}/#{file_name} .`
        end
      end
    end

    def move_package_to_cwd
      pkg = "#{tmp_boiler_path}/#{file_name}"
      FileUtils.mv pkg, Dir.pwd if File.exists? pkg
      package_path = File.join "#{Dir.pwd}", "#{file_name}"
    end

  private

    def merge_defaults_with_manifest
      manifest.defaults.deep_merge!(manifest.to_json)
    end

    def abridged_file_name
      @abridged_file_name ||= [
        config[:name],
        config[:version],
        config[:arch],
        config[:build]
      ].join('-')
    end

    def file_name
      abridged_file_name + '.tgz'
    end

    def install_trolley
      <<-code
if [[ `command -v trolley` == "" ]]; then
  wget -qO- --no-check-certificate https://raw.github.com/nicinabox/trolley/master/install.sh | sh -
fi
      code
    end

  end
end
