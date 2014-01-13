require 'boiler/helpers'

module Boiler
  class Base
    include Boiler::Helpers

    def self.unraid?
      /unraid/i =~ `uname -a`.strip
    end

  end
end

if Boiler::Base.unraid?
  pwd = Dir.pwd
  Dir.chdir File.expand_path('../..', __FILE__)
  Bundler.setup(:default)
  Dir.chdir pwd
else
  Bundler.setup(:default)
end

require 'thor'
