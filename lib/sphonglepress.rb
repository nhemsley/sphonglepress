$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_record'
require 'pathname'
require 'logger'

ActiveRecord::Base.logger = Logger.new('sql.log')
ActiveRecord::Base.configurations = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection("development")

require "sphonglepress/extensions.rb"
require "sphonglepress/git.rb"
require "sphonglepress/middleman.rb"
require "sphonglepress/config.rb"
require "sphonglepress/export.rb"
require "sphonglepress/database.rb"
require "sphonglepress/importer.rb"
require "sphonglepress/visitor.rb"

require "sphonglepress/models/base_post"
require "sphonglepress/models/attachment"


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
    method_options :visitor => :string
    def import_site
      pages = Importer.import sitemap_hash
      pages.each { |page| Importer.persist page }
      if options["visitor"]
        puts "requiring #{options["visitor"]}"
        require options["visitor"]
      end
      pages.each { |page| Importer.visit page }
      Visitor.subclasses.each {|s| s.once}
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
    
    desc "dump_db", "dump the current database as latest dump to load from"
    def dump_db
      random = rand(36**8).to_s(36)
      dump_file = "#{::Sphonglepress::DB_DUMP_DIR.join("#{CONFIG['db']['development']['database']}")}-#{random}.sql"
      puts "file: #{dump_file}"
      db_opts = Database.db_opts(CONFIG)

      `mysqldump #{db_opts} > #{dump_file}`
    end
    
    desc "create_static_files", "create the static files to import into wordpress from (you will need a sitemap.yml)"
    def create_static_files
      site = sitemap_hash
      pages = Importer.structure(site)
      
      FileUtils.mkdir_p(STATIC_DIR)
      
      filenames = Importer.filenames_for_site pages
      
      full_files = filenames.map {|file| STATIC_DIR.join("#{file}.html.haml").to_s }
      
      FileUtils.touch(full_files)
    end
    
    desc "export_layout", "export the layout and static files from middleman to wordpress"
    def export_layout
      Middleman.build
      Export.files
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
  WP_DIR = PROJECT_DIR.join(CONFIG["wp_clone_dir"])
  WP_UPLOAD_DIR = WP_DIR.join("wp-content/uploads")
end
