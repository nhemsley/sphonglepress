$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_record'
require 'pathname'
require 'logger'
require "thor"
require 'fileutils'

require "sphonglepress/config.rb"

begin
  if File.exist? 'config/database.yml'
    ActiveRecord::Base.logger = Logger.new('sql.log')
    ActiveRecord::Base.configurations = YAML::load(IO.read('config/database.yml'))
    ActiveRecord::Base.establish_connection("development")
  end
rescue Exception => e
  puts "Error configuring active record:"
  puts e.to_s
end

require "sphonglepress/extensions.rb"
require "sphonglepress/git.rb"
require "sphonglepress/middleman.rb"
require "sphonglepress/export.rb"
require "sphonglepress/database.rb"
require "sphonglepress/watcher.rb"
require "sphonglepress/doc_exporter.rb"

begin
  require "sphonglepress/importer.rb"
  require "sphonglepress/visitors/visitor.rb"
  require "sphonglepress/visitors/attachment_visitor.rb"
  require "sphonglepress/visitors/document_importer.rb"


  require "sphonglepress/models/base_post"
  require "sphonglepress/models/attachment"
rescue Exception => e
  puts "Error requiring importer, visitor & activemodel classes (this can probably be ignored):"
  puts e.to_s
end

module Sphonglepress
  VERSION = '0.0.1'
  
  class App < Thor
    desc "init", "Initialize wordpress directory"
    method_options :wp_git_url => :string, :wp_git_tag => :string, :wp_clone_dir => :string, :sitemap_file => :string
    def init
      opts = DEFAULT_OPTIONS.merge options
      Git.clone(opts)
      Git.checkout(opts)
      Middleman.init(opts)
      Config.create_config(opts)
      
      #FIXME: move this somewhere better
      visitors_dir = TEMPLATE_DIR.join(opts['template'], "visitors")
      `cp -r #{visitors_dir} config/`
    end

    desc "headers_footers", "export headers and footers to wordpress directory"
    def headers_footers
      Middleman.build
      Export.headers_footers
    end

    desc "clean_wp", "clean up the wordpress directory of the external files from middleman"
    def clean_wp
      dirs = Dir[LAYOUT_DIR.join("source").to_s << "/*/"]
      full_dirs = dirs.map {|d| ::Sphonglepress::Config.wp_theme_dir.join(Pathname.new(d).basename)}.join(" ")
      cmd = "rm -rf #{full_dirs}"
      puts cmd
      `#{cmd}`
      cmd = "rm -rf #{WP_UPLOAD_DIR.to_s}/*"
      `#{cmd}`
    end
    
    desc "import_site", "Import the site from sitemap and static files"
    method_options :visitor => :string
    def import_site
      pages = ::Sphonglepress::Importer.import sitemap_hash
      pages.each { |page| Importer.persist page }
      
      require_visitors
      
      ::Sphonglepress::Visitors::Visitor.subclasses.each {|s| s.instance.once}
      
      pages.each { |page| Importer.visit page }
      
      ::Sphonglepress::Visitors::Visitor.subclasses.each {|s| s.instance.after}
    end
    
    desc "create_db", "create the wordpress database"
    def create_db
      Database.create(CONFIG)
    end

    desc "drop_db", "drop the wordpress database"
    def drop_db
      Database.drop(CONFIG)
    end

    desc "load_db", "load the most recent 'clean' database dump"
    def load_db
      Database.drop(CONFIG)
      Database.create(CONFIG)
      db_opts = Database.db_opts(CONFIG)
      latest_dump = Dir["#{::Sphonglepress::DB_DUMP_DIR}/*.sql"].sort_by{ |f| File.mtime(f) }.last
      puts "mysql #{db_opts} < #{latest_dump}"
      `mysql #{db_opts} < #{latest_dump}`
    end
    
    desc "dump_db", "dump the current database as latest dump to load from"
    def dump_db
      random = rand(36**8).to_s(36)
      dump_file = "#{::Sphonglepress::DB_DUMP_DIR.join("#{CONFIG['db']['development']['database']}")}-#{random}.sql"
      puts "file: #{dump_file}"
      db_opts = Database.db_opts(CONFIG)
      FileUtils.mkdir_p ::Sphonglepress::DB_DUMP_DIR

      `mysqldump #{db_opts} > #{dump_file}`
    end
    
    desc "dump_db_live", "dump the current database as database to go live with"
    def dump_db_live
      random = rand(36**8).to_s(36)
      dump_file = "#{::Sphonglepress::DB_DUMP_DIR_LIVE.join("#{CONFIG['db']['development']['database']}")}-#{random}.sql"
      puts "file: #{dump_file}"
      db_opts = Database.db_opts(CONFIG)
      FileUtils.mkdir_p ::Sphonglepress::DB_DUMP_DIR_LIVE

      `mysqldump #{db_opts} > #{dump_file}`
    end
    
    desc "create_static_files", "create the static files to import into wordpress from (you will need a sitemap.yml)"
    def create_static_files
      site = sitemap_hash
      pages = Importer.structure(site)
      
      FileUtils.mkdir_p(STATIC_DIR)
      
      filenames = Importer.filenames_for_site pages
      
      full_files = filenames.
                    map {|file| STATIC_DIR.join("#{file}.html.haml").to_s }.
                    reject {|file| File.exist? file }
      
      FileUtils.touch(full_files)
    end
    
    desc "export_layout", "export the layout and static files from middleman to wordpress"
    def export_layout
      Middleman.build
      Export.files
    end
    
    desc "export", "copy static files to wordpress"
    def export
      Middleman.build
      Export.files
      Export.headers_footers
      ::Sphonglepress::Visitors::Visitor.subclasses.each do |s| 
        s.instance.after
      end
    end
    
    desc "full_refresh", "do a full refresh of the whole shebang (layouts, headers, database, import content)"
    def full_refresh
      clean_wp
      Middleman.clean
      export
      #load_db
      import_site
      
      require_visitors
      
      ::Sphonglepress::Visitors::Visitor.subclasses.each do |s| 
        s.instance.after
      end
    end
    
    desc "watch", "monitor directory & reload on change"
    def watch
      Signal.trap("INT") { exit! }
      Signal.trap("QUIT") { full_refresh }

      puts "Watching"
      Watcher.new(self).watch
    end
    
    desc "import_static_from_doc", "Try and import site structure from site.odt file in the static/document directory"
    def import_static_from_doc
      pages = ::Sphonglepress::Importer.import sitemap_hash
      document_importer_klass = ::Sphonglepress::Visitors::DocumentImporter
      document_importer_klass.instance.once
      pages.each { |page| Importer.visit page, [document_importer_klass]}
    end
    
    desc "export_doc_from_sitemap", "Output a Word document from the sitemap"
    def export_doc_from_sitemap
      pages = ::Sphonglepress::Importer.import sitemap_hash
      exporter = ::Sphonglepress::DocExporter.new(pages)
      output_dir = STATIC_DIR.join("site")
      FileUtils.mkdir_p(output_dir)
      exporter.export(output_dir)
    end
    
    private
    
    def sitemap_hash
      JSON.parse IO.read(::Sphonglepress::CONFIG_DIR.join("sitemap.json"))
      #YAML::load(IO.read(::Sphonglepress::CONFIG_DIR.join("sitemap.yml")))
    end
    
    def require_visitors
      visitors = Dir[CONFIG_DIR.join("visitors").to_s << "/*.rb"].map{|v| "config/visitors/" << Pathname.new(v).basename.to_s}
      visitors.each do |v|
        require Dir.pwd.to_s << "/" << v
      end

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
  DB_DUMP_DIR_LIVE = PROJECT_DIR.join("db/live_dumps")
  STATIC_DIR = PROJECT_DIR.join(CONFIG["static_dir"]) rescue nil
  WP_DIR = PROJECT_DIR.join(CONFIG["wp_clone_dir"]) rescue nil
  WP_UPLOAD_DIR = WP_DIR.join("wp-content/uploads") rescue nil
  LAYOUT_DIR = PROJECT_DIR.join(CONFIG["middleman_dir"]) rescue nil
  BUILD_DIR = PROJECT_DIR.join(CONFIG["middleman_dir"], "build") rescue nil
end
