require 'fssm'

module Sphonglepress
  class Watcher
    def initialize(app)
      @app = app
    end
      
    def watch
      puts ::Sphonglepress::LAYOUT_DIR.join("source")
      myself = self
      while true do
        begin
          FSSM.monitor do
            
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
          puts "Caught Exception #{e.message}"
        end
      end
    end
    
    def middleman
      begin
        puts "Middleman directory changed, reloading site content"
        @app.import_site
        @app.export
        puts "DONE"
      rescue Exception => e
          puts "Caught Exception while reloading site content: #{e.message}"
      end
    end
    
    def config_sitemap
        puts "Config dir changed, Creating any static files not created"
        @app.create_static_files
        puts "DONE"       
    end
  end
end