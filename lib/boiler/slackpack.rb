require 'boiler/helpers'

module Boiler
  module Slackpack
    include Boiler::Helpers

    def defaults
      {
        arch: 'noarch',
        build: 'unraid'
      }
    end

    def ignores
      %w(.git)
    end

    def required
      %w(name version)
    end

    def run_tasks(tmp, config)
      if config.include? :tasks
        config[:tasks].each do |task|
          status "Running #{task}"
          `#{task}`
        end
      end
    end

    def gzip(src, name)
      if unraid?
        current_dir = `pwd`

        `cd #{src} &&
         makepkg -l -c y ../#{name}.tgz &&
         mv ../#{name}.tgz #{current_dir}`
      else
        `tar czfP #{name}.tgz #{src}`
      end
    end

    def prefix_files(dir, config)
      config[:prefix].each do |prefix, srcs|
        dest = "#{dir}/#{prefix}"
        FileUtils.mkdir_p dest
        srcs.each do |src|
          fullpath = "#{dir}/#{src}"
          FileUtils.mv fullpath, dest
        end
      end
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

    def pack(src)
      config = defaults.merge(JSON.parse(File.read(manifest(src)), {
        :symbolize_names => true
      }))

      name = package_name(config)
      tmp_dir = "/tmp/boiler/#{name}"

      copy_files_to_tmp src, tmp_dir, config
      prefix_files tmp_dir, config
      gzip(tmp_dir, name)

      FileUtils.rm_rf tmp_dir
      name
    end

  end
end
