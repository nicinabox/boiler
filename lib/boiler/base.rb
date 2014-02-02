require 'rubygems'
require 'bundler'
require 'boiler/helpers'

module Boiler
  class Base
    include Boiler::Helpers
    include Boiler::PathHelpers

    def installed(name)
      wildcard = name ? "#{name}*" : "**"
      Dir.glob("/var/log/boiler/#{wildcard}")
    end

  end
end


if Boiler::Helpers.unraid?
  Dir.chdir File.expand_path('../..', __FILE__) do
    Bundler.setup(:default)
  end
else
  Bundler.setup(:default)
end

require 'thor'
