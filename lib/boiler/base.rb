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
  pwd = Dir.pwd
  Dir.chdir File.expand_path('../..', __FILE__)
  Bundler.setup(:default)
  Dir.chdir pwd
else
  Bundler.setup(:default)
end

require 'thor'
