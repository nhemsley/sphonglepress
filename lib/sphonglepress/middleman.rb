module Sphonglepress
  class Middleman
    
    
    class << self
      def init(options)
        site = options['middleman_dir']
        puts "Creating Middleman static site"
        `mm-init #{site}`

        `rm #{site}/source/*.erb`
        to_copy = Dir["#{Sphonglepress::App::TEMPLATE_DIR}/#{options['template']}/middleman/*.haml"]
        to_copy.each do |c|
        `cp #{c} #{site}/source`
        end

      end
      
      def build
        cwd = Dir.pwd
        Dir.chdir ::Sphonglepress::Config.config["middleman_dir"]
        puts `mm-build`
        Dir.chdir cwd
      end
      
      def clean
        cwd = Dir.pwd
        Dir.chdir ::Sphonglepress::Config.config["middleman_dir"]
        puts `rm -rf build`
        Dir.chdir cwd
      end
    end
    
  end
end