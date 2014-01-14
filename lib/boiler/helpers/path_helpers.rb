module Boiler
  module PathHelpers
    def tmp_boiler_path
      "/tmp/boiler"
    end

    def env_path
      "#{usr_local_path}/env"
    end

    def bin_path
      "#{usr_local_path}/bin"
    end

    def usr_local_path
      "usr/local/boiler/#{name_to_param}"
    end

    def docs_path
      "usr/docs/#{name_to_param}"
    end

    def configs_path
      "boot/plugins/custom/#{name_to_param}/_config"
    end

    def manifest_path
      "var/log/boiler/#{name_to_param}"
    end

  end
end
