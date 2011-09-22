require 'fssm'

module Sphonglepress
  class Watcher
    def initialize(app)
      @app = app
      
    end
      
    def watch
      app = @app
      FSSM.monitor do
        path ::Sphonglepress::STATIC_DIR do
          
          def reload(app)
            app.load_db
            app.import_site
          end
          
          update {|base, relative| reload(app) }
          delete {|base, relative| reload(app) }
          create {|base, relative| reload(app) }
        end
      
        path ::Sphonglepress::LAYOUT_DIR.join("source") do
          update {|base, relative| app.export}
          delete {|base, relative| app.export}
          create {|base, relative| app.export}
        end
      end
    end
  end
end