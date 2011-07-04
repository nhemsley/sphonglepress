$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "sphonglepress/git.rb"
require "sphonglepress/middleman.rb"
require "sphonglepress/config.rb"
require "sphonglepress/export.rb"

require "pathname"

module Sphonglepress
  VERSION = '0.0.1'
  
  class App < Thor
    desc "init", "Initialize wordpress directory"
    method_options :wp_git_url => :string, :wp_git_tag => :string, :wp_clone_dir => :string, :sitemap_file => :string
    def init
      opts = DEFAULT_OPTIONS.merge options
      p opts      
      Git.clone(opts)
      Git.checkout(opts)
      Middleman.init(opts["middleman_dir"])
      Config.create_config(opts)
    end

    desc "headers_footers", "export headers and footers to wordpress directory"
    def headers_footers
      Middleman.build
      Export.headers_footers
    end

    desc "clean_wp", "clean up the wordpress directory of the external files from middleman"
    def clean_wp
      raise Exception "unimplemented"
    end
    
    desc "inmport_site", "Import the site from sitemap and static files"
    def import_sitemap
      
    end
    
    desc "load_database", "load the most recent 'clean' database dump"
    def load_database
      latest_dump = Dir["#{::Sphonglepress::DB_DUMP_DIR}/*.sql"].sort_by{ |f| File.ctime(f) }.last
      puts "mysql -u root #{config["development"]["database"]} < #{latest_dump}"
      `mysql -u root #{config["development"]["database"]} < #{latest_dump}`
    end

    

    APP_DIR = Pathname.new(File.expand_path(File.dirname(__FILE__))).join("..")
    TEMPLATE_DIR = APP_DIR.join("templates")
    DEFAULT_OPTIONS = YAML::load(IO.read(TEMPLATE_DIR.join("config/settings.yml")))
    
  end

  PROJECT_DIR = Pathname.new(File.expand_path(Dir.pwd))
  CONFIG_DIR = PROJECT_DIR.join("config")
  DB_DIR = PROJECT_DIR.join("db")
  DB_DUMP_DIR = PROJECT_DIR.join("db/dumps")
end