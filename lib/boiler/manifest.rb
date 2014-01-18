require 'boiler/base'

module Boiler
  class Manifest < Base
    include Thor::Base
    include Thor::Actions

    attr_accessor :path, :name, :name_to_param

    def initialize(path, name = nil)
      @path = path
      @name = name || File.basename(path)
      @name_to_param = to_simple_param @name
    end

    def required
      %w(name version)
    end

    def defaults
      simple_defaults.merge({
        arch: 'noarch',
        build: 'unraid',
        prefix: {
          :"#{usr_local_path}" => [
              'bin',
              'lib',
              'Gemfile*'
          ],
          :"#{configs_path}" => [
            'config/*'
          ],
          :"#{docs_path}" => [
            'README.*',
            'LICENSE*'
          ],
          :"#{manifest_path}" => [
            'boiler.json'
          ]
        },
        ignore: [],
        symlink: {},
        tasks: []
      })
    end

    def simple_defaults
      {
        name: name,
        version: '0.1.0',
        authors: [],
        license: 'MIT',
        dependencies: {},
        post_install: []
      }
    end

    def wizard(config = {})
      config[:name]        = ask "name:",        default: default(config[:name], File.basename(Dir.pwd))
      config[:version]     = ask "version:",     default: default(config[:version], '0.1.0')
      config[:authors]     = ask "authors:",     default: default(config[:authors], name_and_email)
      config[:description] = ask "description:", default: config[:description]
      config[:homepage]    = ask "homepage:",    default: config[:homepage]
      config[:license]     = ask "license:",     default: default(config[:license], 'MIT')

      config
    end

    def to_json
      JSON.parse(File.read(file_path),
                 :symbolize_names => true)
    end

    def exists?
      File.exists? file_path
    end

    def file_path
      "#{path}/boiler.json"
    end

  private

    def default(*vals)
      vals.each do |val|
        return val unless (val.nil? or val.empty?)
      end
    end

    def name_and_email
      "#{git_config('user.name')} <#{git_config('user.email')}>"
    end

    def git_config(key)
      Git.global_config(key)
    end

  end
end
