$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_record'

require "sphonglepress/git.rb"
require "sphonglepress/middleman.rb"
require "sphonglepress/config.rb"
require "sphonglepress/export.rb"
require "sphonglepress/database.rb"

require "pathname"

module Sphonglepress
  VERSION = '0.0.1'
  
  class App < Thor
    desc "init", "Initialize wordpress directory"
    method_options :wp_git_url => :string, :wp_git_tag => :string, :wp_clone_dir => :string, :sitemap_file => :string
    def init
      opts = DEFAULT_OPTIONS.merge options
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
    
    desc "import_site", "Import the site from sitemap and static files"
    def import_site
      pages = Sitemap.import sitemap_hash
      pages.each { |page| Sitemap.persist page }
      pages.each { |page| Sitemap.visit page }
    end
    
    desc "load_db", "load the most recent 'clean' database dump"
    def load_db
      Database.drop(CONFIG)
      Database.create(CONFIG)
      db_opts = Database.db_opts(CONFIG)
      latest_dump = Dir["#{::Sphonglepress::DB_DUMP_DIR}/*.sql"].sort_by{ |f| File.ctime(f) }.last
      puts "mysql #{db_opts} < #{latest_dump}"
      `mysql #{db_opts} < #{latest_dump}`
    end

    private
    
    def sitemap_hash
      YAML::load(IO.read(::Sphonglepress::CONFIG_DIR.join("sitemap.yml")))
    end

    APP_DIR = Pathname.new(File.expand_path(File.dirname(__FILE__))).join("..")
    TEMPLATE_DIR = APP_DIR.join("templates")
    DEFAULT_OPTIONS = YAML::load(IO.read(TEMPLATE_DIR.join("config/settings.yml")))
  end

  PROJECT_DIR = Pathname.new(File.expand_path(Dir.pwd))
  CONFIG_DIR = PROJECT_DIR.join("config")
  ENV_MODE = "development"
  CONFIG = Config.config
  

  DB_DIR = PROJECT_DIR.join("db")
  DB_DUMP_DIR = PROJECT_DIR.join("db/dumps")
  STATIC_DIR = PROJECT_DIR.join(CONFIG["static_dir"])

  begin
    ActiveRecord::Base.establish_connection(CONFIG["db"][ENV_MODE])
  rescue
    
  end
end

#after activerecord::base.establish_connection
begin
  require "sphonglepress/sitemap.rb"
rescue
end