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
        @app.import_site
        puts "DONE"
      rescue Exception => e
          puts "Caught Exception while reloading site content: #{e.message}"
      end
    end
    
  end
end
