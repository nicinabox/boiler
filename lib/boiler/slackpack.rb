require 'boiler/helpers'

module Boiler
  module Slackpack
    include Boiler::Helpers

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
          :"usr/local/#{to_simple_param name}" => ['bin', 'lib', 'Gemfile*'],
          :"boot/plugins/custom/#{to_simple_param name}" => ['config'],
          :"usr/docs/#{to_simple_param name}" => ['README.*'],
          :"var/log/boiler/#{to_simple_param name}" => ['boiler.json']
        },
        ignore: [],
        post_install: []
      }
    end

    def required
      %w(name version)
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
      config[:symlink].each do |src, dest|
        config[:post_install] << "ln -sf #{src} #{dest}"
      end if config[:symlink]
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

        config[:post_install].unshift deps.join "\n"
      end
    end

    def setup_post_install(tmp_dir, config)
      config[:post_install].each do |cmd|
        FileUtils.mkdir_p "#{tmp_dir}/install"

        File.open("#{tmp_dir}/install/doinst.sh", "a") do |f|
          f << "#{cmd}\n"
        end

      end if config[:post_install]
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

      copy_files_to_tmp src, tmp_dir, config

      setup_dependencies tmp_dir, config
      setup_symlinks tmp_dir, config
      setup_post_install tmp_dir, config

      prefix_files tmp_dir, config
      gzip(tmp_dir, name)

      FileUtils.rm_rf Dir.glob("#{tmp_boiler}/#{config[:name]}*")
      name + '.tgz'
    end

  end
end
