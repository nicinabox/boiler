require 'boiler/base'

module Boiler
  class ConvertPlg < Base
    include Thor::Base
    include Thor::Actions
    source_root Dir.pwd

    attr_accessor :file, :base_file_name, :xml, :tmp, :manifest,
                  :plugin, :options

    def initialize(plg)
      @file           = File.read plg
      @base_file_name = File.basename(plg).gsub(/\.plg$/, '')
      @tmp            = "#{File.dirname(File.expand_path(plg))}/#{base_file_name}"
      @manifest       = Manifest.new(tmp)
      @config         = @manifest.simple_defaults
      @xml            = Nokogiri::XML(file)
      @plugin         = xml.css('PLUGIN')
      @files          = plugin.css('FILE')

      # For Thor
      @options           = {}
      @destination_stack = [@tmp]
    end

    def build
      copy_files_to_tmp
      fetch_assets
      update_doinst
      @config.deep_merge! @manifest.wizard(@config)
      add_dependencies_to_manifest
      create_manifest
    end

    def map_dependencies
      @files.map { |f|
        if dependency_url? f.css('URL').text
          f.css('URL').text
            .gsub('--no-check-certificate', '')
            .gsub('-q', '')
            .strip
        end
      }.compact
    end

    def map_assets
      @files.map { |f|
        if dependency_asset? f.css('URL').text
          {
            :"#{tmp}#{f['Name']}" => f.css('URL').text
                                      .gsub('--no-check-certificate', '')
                                      .gsub('-q', '')
                                      .strip()
          }
        end
      }.compact
    end

    def map_files
      @files.map { |f|
        unless dependency_asset? f['Name'] or
               dependency_url? f['Name']

          { :"#{f['Name']}" => f.css('INLINE').text }
        end
      }.compact
    end

    def map_scripts
      @files.map { |f|
        f['Name'] if f['Run'] == '/bin/bash'
      }.compact
    end

    def add_dependencies_to_manifest
      map_dependencies.each do |url|
        dep = { :"#{dependency_name(url)}" => url }
        @config[:dependencies].merge!(dep)
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
      create_file @manifest.file_path do
        JSON.pretty_generate(@config)
      end
    end

    def fetch_assets
      map_assets.each do |asset|
        dest    = asset.keys.first.to_s
        remote  = asset[dest.to_sym]
        dirname = File.dirname dest

        `mkdir -p #{dirname} && wget -q #{remote} -O #{dest}`
      end
    end

  private

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
