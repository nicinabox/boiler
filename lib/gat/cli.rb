require 'thor'

module Gat
  class CLI < Thor

    desc 'install NAME', 'Install a package by name'
    def install(name)
      # fetch name
      # clone repo
      # pack with slackpack or fallback on makepkg
    end

    desc 'register NAME ENDPOINT', 'Register a package'
    def register(name, endpoint)
      # check if private
      # clone locally to tmp
      # check if gat.json
      # save name and endpoint
      # remove tmp dir
    end

    desc 'search NAME', 'Search for packages'
    def search(name)
      # GET /packages/search/:fragment
    end

  end
end
