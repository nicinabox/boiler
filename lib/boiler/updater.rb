require 'boiler/helpers'

module Boiler
  class Updater
    include Thor::Base
    include Boiler::Helpers

    def check
      if update_available?
        status "A newer version is available.", :green
        response = yes? "Would you like to update now?"

        if response
          status "Updating"
          update('boiler')
        end
      end
    end

    def update_available?
      Boiler::VERSION < remote_version
    end

  private

    def remote_version
      response = HTTParty.get('https://api.github.com/repos/nicinabox/boiler/tags',
                              :headers => { 'User-Agent' => 'boiler' })
      response.first['name']
    end
  end
end
