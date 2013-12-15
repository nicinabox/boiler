require 'thor'
require 'boiler/helpers'

module Boiler
  class CLI < Thor
    include HTTParty
    include Grit
    include Boiler::Helpers

    base_uri 'http://boiler-registry.herokuapp.com'
    format :json

    desc 'install NAME', 'Install a package by name'
    def install(name_or_url)
      status "Downloading #{name_or_url}"

      if url? name_or_url
        url = name_or_url
        package = self.class.get(url)
        dest = clone_repo(`basename #{url}`, url)
      else
        package = self.class.get("/packages/#{name}?install=true")
        dest = clone_repo(package['name'], package['url'])
      end

      status 'Packaging'
      # TODO: pack with slackpack or fallback on makepkg
      `slackpack #{dest}`

      # TODO: move to /boot/extra
      # TODO: run installpkg

      status 'Installed!', :green
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

      dest = clone_repo(name, url)

      unless manifest_exists? dest
        status 'Package is missing boiler.json', :red
        cleanup dest
        abort
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
    def search(fragment)
      packages = self.class.get("/packages/search/#{fragment}")

      packages.each do |package|
        pretty_print [package['name'], package['url']]
      end
    end

  end
end
