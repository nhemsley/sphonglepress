require 'fssm'

module Sphonglepress
  class Watcher
    def initialize(app)
      @app = app
    end
      
    def watch
      myself = self
      while true do
        begin
          FSSM.monitor do
            path ::Sphonglepress::STATIC_DIR do
              
              update {|base, relative| myself.static }
              delete {|base, relative| myself.static }
              create {|base, relative| mysqlf.static }
            end
            
            path ::Sphonglepress::LAYOUT_DIR.join("source") do
              update {|base, relative| myself.middleman }
              delete {|base, relative| myself.middleman }
              create {|base, relative| myself.middleman }
            end
            
            path ::Sphonglepress::CONFIG_DIR do
              update {|base, relative| myself.config_sitemap }
              delete {|base, relative| myself.config_sitemap }
              create {|base, relative| myself.config_sitemap }
            end
            
          end
          
        rescue Exception => e
          
        end
      end
    end
    
    def static
        puts "Static dir changed, reloading site content"
        @app.load_db
        @app.import_site
        puts "DONE"

    end
    
    def middleman
        puts "Middleman directory changed, reloading static assets"
        @app.export
        puts "DONE"
      end
    
    def config_sitemap
        puts "Config dir changed, Creating any static files not created"
        @app.create_static_files
        puts "DONE"       
    end
  end
end