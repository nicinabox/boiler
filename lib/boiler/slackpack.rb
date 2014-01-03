require 'boiler/helpers'

module Boiler
  module Slackpack
    include Boiler::Helpers
    include Thor::Actions

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
          :"usr/local/boiler/#{to_simple_param name}" => ['bin', 'lib', 'Gemfile*'],
          :"#{configs(name)}" => ['config/*'],
          :"usr/docs/#{to_simple_param name}" => ['README.*'],
          :"var/log/boiler/#{to_simple_param name}" => ['boiler.json']
        },
        ignore: [],
        symlink: {},
        post_install: []
      }
    end

    def required
      %w(name version)
    end

    def configs(name)
      "/boot/plugins/custom/#{to_simple_param name}/_config"
    end

    def run_tasks(tmp, config)
      config[:tasks].each do |task|
        status "Running #{task}"
        `#{task}`
      end if config[:tasks]
    end

    def gzip(src, name)
      current_dir = `pwd`

      if unraid?
        `cd #{src} && makepkg -c y ../#{name}.tgz`
      else
        `cd #{src} && tar -czf ../#{name}.tgz .`
      end

      `mv #{tmp_boiler}/#{name}.tgz #{current_dir}`
    end

    def prefix_files(dir, config)
      config[:prefix].each do |prefix, srcs|
        dest = "#{dir}/#{prefix}"
        FileUtils.mkdir_p dest
        srcs.each do |src|
          fullpath = "#{dir}/#{src}"
          FileUtils.mv Dir.glob(fullpath), dest
        end
      end if config[:prefix]
    end

    # Does not copy files beginning with dot!
    def copy_files_to_tmp(src, dest, config)
      paths = Dir.glob("#{src}/**/*")
      paths.reject! do |path|
        File.directory? path or
        config[:ignore].include? File.basename(path)
      end

      FileUtils.mkdir_p(dest)
      paths.each do |path|
        dir, name = File.dirname(path), File.basename(path)
        target = dir.gsub(src, dest)

        FileUtils.mkdir_p target
        FileUtils.cp_r path, "#{target}/#{name}"
      end
    end

    def package_name(c)
      "#{c[:name]}-#{c[:version]}-#{c[:arch]}-#{c[:build]}"
    end

    def setup_symlinks(tmp_dir, config)
      bins = Dir.glob "bin/*"
      if bins.any?
        bin_map = bins.map { |path|
          name = File.basename path
          { :"/usr/local/boiler/#{to_simple_param name}/#{path}" => "/usr/local/bin/#{name}" }
        }

        config[:symlink].merge! bin_map.first
      end

      config[:symlink].each do |src, dest|
        config[:post_install] << "ln -sf #{src} #{dest}"
      end
    end

    def setup_dependencies(tmp_dir, config)
      if config[:dependencies]
        deps = config[:dependencies].map do |pkg, version|
          if /^http/ =~ version
            "trolley install #{version}"
          else
            "trolley install #{pkg} #{version}"
          end
        end

        prepend_to_file "#{tmp_dir}/install/doinst.sh", "#{deps.join("\n")}\n"
      end
    end

    def setup_configs(tmp_dir, config)
      cmds = []
      src_config_dir    = configs(config[:name])
      target_config_dir = src_config_dir.gsub('_config', 'config')

      cmds << <<-CMD.gsub(/^ {8}/, '')
        if [ ! -f #{target_config_dir} ]; then
          cp -r #{src_config_dir} #{target_config_dir}
        fi
      CMD

      cmds << <<-CMD.gsub(/^ {8}/, '')
        rm -rf #{src_config_dir}
      CMD

      config[:post_install].unshift cmds.join("\n")
    end

    def setup_post_install(tmp_dir, config)
      config[:post_install].each do |cmd|
        File.open("#{tmp_dir}/install/doinst.sh", "a") do |f|
          f << "#{cmd}\n"
        end

      end if config[:post_install]
    end

    def prepend_post_install(tmp_dir, config)
      if config[:prepend_post_install]
        prepend_to_file "#{tmp_dir}/install/doinst.sh", "#{config[:prepend_post_install].join("\n")}\n"
      end
    end

    def create_package(src)
      src = File.expand_path src

      src.gsub!(/\/$/, '') if /\/$/ =~ src

      config = JSON.parse(File.read(manifest(src)), {
        :symbolize_names => true
      })

      d = defaults(config[:name])
      config = d.deep_merge!(config)

      name = package_name(config)
      tmp_dir = "#{tmp_boiler}/#{name}"

      FileUtils.mkdir_p "#{tmp_dir}/install"
      FileUtils.touch   "#{tmp_dir}/install/doinst.sh"

      copy_files_to_tmp src, tmp_dir, config

      setup_dependencies tmp_dir, config
      setup_symlinks tmp_dir, config
      setup_configs tmp_dir, config
      setup_post_install tmp_dir, config

      prepend_post_install tmp_dir, config

      prefix_files tmp_dir, config
      gzip(tmp_dir, name)

      FileUtils.rm_rf Dir.glob("#{tmp_boiler}/#{config[:name]}*")
      name + '.tgz'
    end

  end
end
