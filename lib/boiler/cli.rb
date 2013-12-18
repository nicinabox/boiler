require 'bundler/setup'
require 'thor'
require 'crack'
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

    desc 'list [NAME]', 'List installed packages'
    def list(name=nil)
      files = installed_packages(name)
      files.each do |f|
        config = JSON.parse File.read f
        three_columns config['name'], config['version'], config['description']
      end
    end

    desc 'info NAME', 'Get info on installed package'
    def info(name)
      packages = installed_packages(name)
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

    desc 'init', 'Create a boiler.json in the current directory'
    def init
      config = manifest_wizard defaults(File.basename(Dir.pwd))

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

    # This converter was designed against Influencer's plg code. It's not guaranteed to work with any plg.
    desc 'convert PLG', 'Convert a plg to boiler package'
    def convert(plg)
      file    = File.read plg
      name    = File.basename(plg).gsub(/\.plg$/, '')
      xml     = Crack::XML.parse(file)
      plugin  =  xml['PLUGIN']
      tmp_dir = "#{File.dirname(plg)}/#{name}"
      config  = defaults(name)

      status "Converting #{config[:name]}"

      FileUtils.mkdir_p(tmp_dir)

      plugin['FILE'].each do |f|
        # Dependencies
        if f['URL']
          url = extract_dependency(f) || extract_asset(f)
          if url.is_a? String
            config[:dependencies] << url
          else
            asset_dest = "#{tmp_dir}#{url[:dest]}"
            asset      = File.basename asset_dest
            dirname    = File.dirname asset_dest
            fetch_url  = url[:url]

            status "Fetching #{asset}"
            `mkdir -p #{dirname} && wget -q #{fetch_url} -O #{asset_dest}`
          end

        # Installer
        elsif f['Run'] == '/bin/bash'
          config[:post_install] << f['INLINE']

        # Create files
        else
          file_name = f['Name']
          unless /var\/log\/plugins/ =~ file_name
            FileUtils.mkdir_p(tmp_dir + File.dirname(file_name))
            File.open("#{tmp_dir}#{file_name}", "w") do |f_dest|
              f_dest.write f['INLINE']
            end
          end
        end
      end

      config.deep_merge! manifest_wizard(config)

      File.open("#{tmp_dir}/boiler.json", 'w') do |f_boiler|
        f_boiler.write JSON.pretty_generate(config)
      end

      status "Please review your package at #{tmp_dir}", :green
    end

    desc 'version', 'Prints version'
    def version
      puts ::Boiler::VERSION
    end
  end
end
