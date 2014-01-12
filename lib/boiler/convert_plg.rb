require 'boiler/helpers'

module Boiler
  class ConvertPlg
    include Thor::Base
    include Thor::Actions
    include Boiler::Helpers
    source_root Dir.pwd

    attr_accessor :file, :base_file_name, :xml, :tmp, :config,
                  :plugin, :options

    def initialize(plg)
      @file           = File.read plg
      @base_file_name = File.basename(plg).gsub(/\.plg$/, '')
      @config         = defaults
      @xml            = Crack::XML.parse(file)
      @plugin         = xml['PLUGIN']
      @tmp            = "#{File.dirname(File.expand_path(plg))}/#{base_file_name}"

      # For Thor
      @options           = {}
      @destination_stack = [@tmp]
    end

    def build
      copy_files_to_tmp
      config.deep_merge! manifest_wizard(config)
      create_manifest
    end

    def copy_files_to_tmp
      FileUtils.mkdir_p(tmp)

      plugin['FILE'].each do |f|
        # Dependencies
        if f['URL']
          collect_dependencies(f)

        # Post installer
        elsif f['Run'] == '/bin/bash'
          config[:post_install] << f['INLINE']

        # Create files
        else
          create_package_file(f)
        end
      end
    end

    def create_manifest
      create_file "#{tmp}/boiler.json" do
        JSON.pretty_generate(config)
      end
    end

  private

    def collect_dependencies(f)
      url = extract_dependency(f) || extract_asset(f)

      # Add to dependencies
      if url.is_a? String
        config[:dependencies].merge(
          :"#{dependency_name(url)}" => url
        )

      else
        # Try to download remote assets
        asset_dest = "#{tmp}#{url[:dest]}"
        asset      = File.basename asset_dest
        dirname    = File.dirname asset_dest
        fetch_url  = url[:url]

        `mkdir -p #{dirname} && wget -q #{fetch_url} -O #{asset_dest}`
      end
    end

    def create_package_file(f)
      path = f['Name']

      unless /var\/log\/plugins/ =~ path
        create_file "#{tmp}#{path}" do
          f['INLINE']
        end
      end
    end

    def dependency_name(url)
      basename = File.basename url
      basename.gsub(/\..+{3}/, '')
    end

    def defaults
      {
        name: base_file_name,
        version: '0.1.0',
        authors: [],
        license: 'MIT',
        dependencies: {},
        post_install: []
      }
    end

    def extract_dependency(f)
      if /tx|jz$/ =~ f['URL']
        f['URL']
      end
    end

    def extract_asset(f)
      {
        :dest => f['Name'],
        :url  => f['URL']
      }
    end

  end
end
