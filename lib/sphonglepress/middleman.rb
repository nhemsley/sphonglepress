module Sphonglepress
  class Middleman
    
    
    class << self
      def init(site)
        puts "Creating Middleman static site"
        `mm-init #{site}`
        
        `cp #{::Sphonglepress::App::TEMPLATE_DIR.join("middleman/layout.haml")} #{site}/views`
        `cp #{::Sphonglepress::App::TEMPLATE_DIR.join("middleman/default.html.haml")} #{site}/views`

      end
      
      def build
        cwd = Dir.pwd
        Dir.chdir ::Sphonglepress::Config.config["middleman_dir"]
        `mm-build`
        Dir.chdir cwd
      end
    end
    
  end
end