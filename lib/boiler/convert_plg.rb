require 'boiler/base'

module Boiler
  class ConvertPlg < Base
    include Thor::Base
    include Thor::Actions
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
      update_doinst
      config.deep_merge! manifest_wizard(config)
      add_dependencies_to_config
      create_manifest
    end

    def map_dependencies
      plugin['FILE'].map { |f|
        if dependency_url? f['URL']
          f['URL'].gsub('--no-check-certificate', '').strip
        end
      }.compact
    end

    def map_assets
      plugin['FILE'].map { |f|
        if dependency_asset? f['URL']
          f['URL']
        end
      }.compact
    end

    def map_files
      plugin['FILE'].map { |f|
        unless dependency_asset? f['Name'] or
               dependency_url? f['Name']

          { :"#{f['Name']}" => f['INLINE'] }
        end
      }.compact
    end

    def map_scripts
      plugin['FILE'].map { |f|
        f['Name'] if f['Run'] == '/bin/bash'
      }.compact
    end

    def add_dependencies_to_config
      map_dependencies.each do |url|
        dep = { :"#{dependency_name(url)}" => url }
        config[:dependencies].merge!(dep)
      end
    end

    def copy_files_to_tmp
      FileUtils.mkdir_p(tmp)

      map_files.each do |data|
        create_package_file(data)
      end
    end

    def update_doinst
      post_installer = "#{tmp}/install/doinst.sh"

      create_file post_installer unless File.exist? post_installer

      append_to_file post_installer do
        map_scripts.join("\n") + "\n"
      end
    end

    def create_manifest
      create_file "#{tmp}/boiler.json" do
        JSON.pretty_generate(config)
      end
    end

  private

    def collect_dependencies(f)
      dep = extract_dependency(f) || extract_asset(f)

      # Add to dependencies
      if dep.is_a? String
        dep.gsub!('--no-check-certificate', '')
        config[:dependencies].merge!(:"#{dependency_name(dep)}" => dep)

      else
        # Try to download remote assets
        asset_dest = "#{tmp}#{dep[:dest]}"
        asset      = File.basename asset_dest
        dirname    = File.dirname asset_dest
        fetch_url  = dep[:url]

        `mkdir -p #{dirname} && wget -q #{fetch_url} -O #{asset_dest}`
      end
    end

    def create_package_file(data)
      path = data.keys.first.to_s

      unless /var\/log\/plugins/ =~ path
        create_file "#{tmp}#{path}" do
          data[path.to_sym]
        end
      end
    end

    def dependency_name(url)
      basename = File.basename url
      basename.gsub(/\.\S{3}$/, '')
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
      f['URL'] if dependency_url? f['URL']
    end

    def extract_asset(f)
      {
        :dest => f['Name'],
        :url  => f['URL']
      }
    end

    def dependency_url?(url)
      /tx|jz$/ =~ url
    end

    def dependency_asset?(url)
      /png|jpg|jpeg|gif$/ =~ url
    end

  end
end
