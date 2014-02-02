require 'httparty'
require 'fileutils'
require 'deep_merge'
require 'crack'
require 'boiler/helpers/path_helpers'

module Boiler
  module Helpers

    def status(message, color = nil)
      say "=> #{message}", color
    end

    def to_simple_param(string)
      string.downcase.gsub(' ', '-')
    end

    def unraid?
      /unraid/i =~ `uname -a`
    end
    module_function :unraid?

    def cleanup(dest)
      return unless File.exists? dest
      FileUtils.rm_rf dest
    end

    def url?(url)
      HTTParty.get(url).code == 200 rescue nil
    end

  end
end
