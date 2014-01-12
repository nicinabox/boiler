require 'rubygems'
require 'bundler/setup'
require 'boiler/helpers'
require 'boiler/package'
require 'boiler/convert_plg'
require 'boiler/version'

module Boiler
  class CLI < Thor
    include HTTParty
    include Boiler::Helpers

    base_uri 'http://boiler-registry.herokuapp.com'
    format :json

    def initialize(*args)
      super
      check_for_update
    end

    desc 'pack DIR', 'Pack a directory for distribution'
    def pack(dir)
      name = File.basename File.expand_path dir

      status "Packing #{name}"

      package = Package.new dir
      name = package.build

      pkg = "#{Dir.pwd}/#{name}"
      status "Done! Your package is at #{pkg}", :green
      pkg
    end

    desc 'deploy DIR HOST', 'Pack and copy to an unRAID machine (for testing)'
    def deploy(dir, host)
      pkg = pack(dir)
      name = File.basename pkg

      status 'Copying'

      `scp #{pkg} #{host}`
      FileUtils.rm pkg

      status "Your package was copied to #{host}/#{name}", :green
    end

    desc 'install NAME [VERSION]', 'Install a package by name'
    def install(name_or_url, version=nil)
      status "Downloading #{name_or_url}"

      if url? name_or_url
        url = name_or_url
        package = self.class.get(url)
        repo = clone_repo(`basename #{url}`, url, version)
      else
        name = name_or_url
        package = self.class.get("/packages/#{name}?install=true")
        repo = clone_repo(package['name'], package['url'], version)
      end

      status "Packaging #{repo.last}"
      pkg = Package.new repo.first.dir.to_s
      packed_name = pkg.build

      if unraid?
        FileUtils.mkdir_p '/boot/extra'
        FileUtils.mv "#{packed_name}", '/boot/extra'

        status "Installing"
        puts `installpkg /boot/extra/#{packed_name}`

        status 'Installed!', :green
      else
        status "Can't install. Not an unRAID machine.", :yellow
      end
    end

    desc 'remove NAME', 'Remove (uninstall) a package'
    def remove(name)
      if unraid?
        `removepkg #{name}`
      end
    end

    desc 'register NAME URL', 'Register a package'
    def register(name, url)
      unless git_protocol? url
        unless url = convert_to_git_protocol(url)
          status 'Url must use git:// protocol', :red
          abort
        end
      end

      do_register = yes? '[yN]', 'Are you sure you want to register this package? '

      unless do_register
        status 'Not registering', :red
        abort
      end

      status "Validating #{name}"

      unless public_repo? url
        status 'Package must be a public repo', :red
        abort
      end

      repo = clone_repo(name, url)
      dest = repo.first.dir.to_s

      unless manifest_exists? dest
        status 'Package is missing boiler.json', :red
        cleanup dest
        abort
      end

      metadata = JSON.parse File.read manifest(dest)
      required.each do |key, val|
        if !metadata.has_key?(key) and !metadata[key].empty?
          status "boiler.json requires #{key}", :red
          abort
        end
      end

      status "Registering"
      response = self.class.post('/packages',
        body: {
          name: name,
          url: url
        })

      if response['errors']
        response['errors'].each do |error|
          status error, :red
        end
      else
        status "Registered!", :green
      end
    end

    desc 'search NAME', 'Search for packages'
    def search(fragment=nil)
      packages = self.class.get("/packages/search/#{fragment}")
      print_table packages.map { |p| [p['name'], p['url']] }
    end

    desc 'list [NAME]', 'List installed packages'
    def list(name=nil)
      files = installed_packages(name)
      configs = files.map { |f| JSON.parse File.read(f) }
      print_table configs.map { |c| [c['name'], c['version'], c['description']] }
    end

    desc 'info NAME', 'Get info on installed package'
    def info(name)
      packages = installed_packages("#{name}*")
      if packages
        config = JSON.parse File.read packages.first

        keys = %w(name version description license authors)
        keys.each do |key|
          value = config[key]
          value = value.join(', ') if value.is_a? Array
          two_columns "#{key.capitalize}:", value if value
        end
      else
        status "No package named #{name}"
      end
    end

    desc 'open NAME', "Open a package's homepage"
    def open(name)
      package = self.class.get("/packages/#{name}")
      url = package['url'].gsub(/^git/, 'http')

      packages = installed_packages(name)

      if packages.any?
        config = JSON.parse File.read packages
        url = config['homepage'] if config['homepage'].present?
      end

      status "Opening #{url}"
      `open #{url}`
    end

    desc 'init [DIRECTORY]', 'Create a boiler.json in the specified directory'
    def init(directory = Dir.pwd)
      path = File.expand_path(directory)
      config = manifest_wizard

      FileUtils.mkdir_p path

      File.open("#{path}/boiler.json","w") do |f|
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
