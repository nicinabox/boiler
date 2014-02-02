require 'date'
require 'boiler/base'

module Boiler
  class Updater < Base
    include Thor::Base

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
      if cached_version
        cached_version
      else
        response = HTTParty.get('https://api.github.com/repos/nicinabox/boiler/tags',
                                :headers => { 'User-Agent' => 'boiler' })
        cache_remote_version response.first['name']
      end
    end

    def cache_remote_version(version)
      File.open(cached_version_file, 'w') do |f|
        f.write version
      end
      version
    end

    def cached_version
      if File.exists? cached_version_file
        # Read cached if file is newer
        if File.mtime(cached_version_file) > Date.today.to_time
          File.read(cached_version_file)
        end
      end
    end

    def cached_version_file
      '/tmp/boiler_latest'
    end
  end
end
