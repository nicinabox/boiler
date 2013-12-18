require 'bundler/setup'
require 'thor'
require 'boiler/slackpack'
require 'boiler/helpers'
require 'boiler/version'

module Boiler
  class CLI < Thor
    include HTTParty
    include Boiler::Slackpack
    include Boiler::Helpers

    base_uri 'http://boiler-registry.herokuapp.com'
    format :json

    desc 'pack DIR', 'Pack a directory for distribution'
    def pack(dir)
      name = File.basename dir

      status "Packing #{name}"

      name = create_package dir

      pkg = "#{Dir.pwd}/#{name}"
      status "Done! Your package is at #{pkg}", :green
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
      packed_name = create_package repo.first.dir.to_s

      if unraid?
        FileUtils.mkdir_p '/boot/extra'
        FileUtils.mv "#{packed_name}", '/boot/extra'

        status "Installing"
        `installpkg /boot/extra/#{packed_name}`

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
        status 'Url must use git:// protocol', :red
        abort
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
      required.each do |key|
        unless metadata.has_key? key
          status "boiler.json requires #{key}"
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

      packages.each do |package|
        two_columns package['name'], package['url']
      end
    end

    desc 'list', 'List installed packages'
    def list
      files = Dir.glob("/var/log/boiler/**/boiler.json")
      files.each do |f|
        config = JSON.parse File.read f
        three_columns config['name'], config['version'], config['description']
      end
    end

    desc 'init', 'Create a boiler.json in the current directory'
    def init
      config = {}

      config[:name]    = ask "name:", default: File.basename(Dir.pwd)
      config[:version] = ask "version:", default: '0.1.0'
      config[:authors] = ask "authors:", default: name_and_email
      config[:description] = ask "description:"
      config[:homepage] = ask "homepage:"
      config[:license] = ask "license:", default: 'MIT'

      File.open("boiler.json","w") do |f|
        f.write(JSON.pretty_generate(config))
      end
    end

    desc 'update NAME', 'Update package by name'
    def update(name)
      status 'Removing old package'
      FileUtils.rm Dir.glob("/boot/extra/#{name}*")

      install name
    end

    desc 'version', 'Prints version'
    def version
      puts ::Boiler::VERSION
    end
  end
end
