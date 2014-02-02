require 'boiler/base'
require 'boiler/package'
require 'boiler/repo'
require 'boiler/convert_plg'
require 'boiler/updater'
require 'boiler/version'

module Boiler
  class CLI < Thor
    include HTTParty
    include Boiler::Helpers

    base_uri 'http://boiler-registry.herokuapp.com'
    format :json

    attr_accessor :base

    def initialize(*args)
      super
      @base = Base.new

      updater = Updater.new
      updater.check if unraid?
    end

    desc 'pack DIR', 'Pack a directory for distribution'
    def pack(dir)
      name = File.basename(File.expand_path(dir))

      status "Packing #{name}"

      package      = Package.new dir
      package_path = package.build

      status "Done! Your package is at #{package_path}", :green
      package_path
    end

    desc 'deploy DIR HOST', 'Pack and copy to an unRAID machine (for testing)'
    def deploy(dir, host)
      path      = pack(dir)
      file_name = File.basename path

      status 'Copying'
      `scp #{path} #{host}`

      status 'Removing local package'
      FileUtils.rm path

      status "Your package was copied to #{host}/#{file_name}", :green
    end

    desc 'install NAME [VERSION]', 'Install a package by name'
    def install(name, version=nil)
      status "Downloading #{name}"

      if url? name
        url  = name
        name = nil
      else
        pkg_data = self.class.get("/packages/#{name}?install=true")
        url      = pkg_data['url']
      end

      repo    = Repo.new url, name, version
      base    = repo.clone
      version = repo.release

      status "Packaging #{repo.name}"
      package   = Package.new base.dir.path
      file_name = package.build

      if unraid?
        FileUtils.mkdir_p '/boot/extra'
        FileUtils.mv "#{file_name}", '/boot/extra'

        status "Installing"
        puts `installpkg /boot/extra/#{file_name}`

        status 'Installed!', :green
      else
        status "Can't install. Not an unRAID machine.", :yellow
      end
    end

    desc 'remove NAME', 'Remove (uninstall) a package'
    def remove(name)
      `removepkg #{name}` if unraid?
    end

    desc 'register NAME URL', 'Register a package'
    def register(name, url)
      unless yes? '[yN]', 'Are you sure you want to register this package? '
        status 'Not registering', :red
        abort
      end

      status "Validating #{name}"

      repo = Repo.new url, name
      message = repo.validate
      if message
        status message, :red
        abort
      end

      status "Registering"

      response = self.class.post('/packages',
        body: {
          name: name,
          url: url
        })

      response['errors'].each do |error|
        status error, :red
        abort
      end

      status "Registered!", :green
    end

    desc 'search NAME', 'Search for packages'
    def search(fragment=nil)
      packages = self.class.get("/packages/search/#{fragment}")
      print_table packages.map { |p| [p['name'], p['url']] }
    end

    desc 'list [NAME]', 'List installed packages'
    def list(name=nil)
      dirs      = base.installed name
      manifests = dirs.map { |dir|
        Manifest.new dir
      }

      print_table manifests.map { |manifest|
        c = manifest.to_json
        [c[:name], c[:version], c[:description]]
      }
    end

    desc 'info NAME', 'Get info on installed package'
    def info(name)
      package = base.installed(name)

      if package.any?
        manifest = Manifest.new package.first
        config   = manifest.to_json

        keys = %w(name version description license authors)
        package_info = keys.map { |k|
          key = k.to_sym
          if config[key]
            if config[key].is_a? Array
              config[key] = config[key].join(', ')
            end
            [k.capitalize, config[key]]
          end
        }.compact

        print_table package_info

      else
        status "No package named #{name}"
      end
    end

    desc 'open NAME', "Open a package's homepage"
    def open(name)
      # Open code
      package = self.class.get("/packages/#{name}")
      url = package['url'].gsub(/^git/, 'http')

      # Or open homepage, if available
      packages = base.installed(name)
      if packages.any?
        manifest = Manifest.new packages.first
        config = manifest.to_json
        url = config[:homepage] if config[:homepage].present?
      end

      status "Opening #{url}"
      `open #{url}`
    end

    desc 'init [DIRECTORY]', 'Create a boiler.json in the specified directory'
    def init(directory = Dir.pwd)
      path     = File.expand_path(directory)
      manifest = Manifest.new path
      config   = manifest.wizard

      FileUtils.mkdir_p path

      File.open("#{manifest.file_path}","w") do |f|
        f.write(JSON.pretty_generate(config))
      end

      File.open("#{path}/README.md","w") do |f|
        f.write <<-MD
# #{config[:name]}

#{config[:description]}
        MD
      end
    end

    desc 'update NAME [VERSION]', 'Update package by name'
    def update(name, version=nil)
      status 'Removing old package'
      FileUtils.rm Dir.glob("/boot/extra/#{name}*")

      remove name
      install name, version
    end

    # This converter was designed against Influencer's plg code.
    # It is not guaranteed to be accurate with all plgs.
    desc 'convert PLG', 'Convert a plg to boiler package'
    def convert(plg)
      package = Boiler::ConvertPlg.new plg
      status "Converting #{package.base_file_name}"

      package.build

      status "Please review your package at #{package.tmp}", :green
    end

    desc 'version', 'Prints version'
    def version
      puts ::Boiler::VERSION
    end
  end
end
