require 'yaml'
require 'fileutils'

module Sphonglepress
  class Config
    class << self
      def create_config(config)
        FileUtils.mkdir("config")
        write_config config
      end

      def write_config(config)
        FileUtils.cp(config["sitemap_file"] || "#{::Sphonglepress::App::TEMPLATE_DIR}/config/sitemap.yml", "config/sitemap.yml")
        File.open("config/settings.yml", 'w') {|f| f.write(config.to_yaml.to_s)}
        FileUtils.cp("#{::Sphonglepress::App::TEMPLATE_DIR}/config/database.yml", "config/database.yml")
      end

      def config
        begin
          c = YAML::load(IO.read(::Sphonglepress::CONFIG_DIR.join("settings.yml")))
          c["db"] = YAML::load(IO.read(::Sphonglepress::CONFIG_DIR.join("database.yml"))) rescue nil
          c["middleman_dir"] = Pathname.new(c["middleman_dir"])
          c["wp_clone_dir"] = Pathname.new(c["wp_clone_dir"])
          return c
        rescue
          return {}
        end
      end

      def wp_theme_dir
        config["wp_clone_dir"].join("wp-content/themes", config["wp_theme_dir"])
      end
    end
  end
end