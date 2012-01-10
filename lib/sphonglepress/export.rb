require 'fileutils'
require 'ruby-debug'

module Sphonglepress
  class Export
    class << self
      def headers_footers
        build_dir = ::Sphonglepress::Config.config["middleman_dir"].join("build")
        layout_dir = build_dir.join("headers")
        default_file = layout_dir.join("index.html")
        default_parts = split_file(IO.read(default_file)) rescue nil
        
        other_files = Dir["#{layout_dir}/*.html"]. #without index.html
                    reject {|file| Pathname.new(file).basename.to_s == "index.html"}
        
        others = {}
        other_files.each do |file|
          others[File.basename(file, '.*')] = split_file(IO.read(file))
        end
        
        FileUtils.mkdir_p ::Sphonglepress::Config.wp_theme_dir unless Dir.exist? ::Sphonglepress::Config.wp_theme_dir
        
        if default_parts
          File.open(::Sphonglepress::Config.wp_theme_dir.join("header.php"), 'w') {|file| file.write(default_parts[:header])}
          File.open(::Sphonglepress::Config.wp_theme_dir.join("footer.php"), 'w') {|file| file.write(default_parts[:footer])}
          File.open(::Sphonglepress::Config.wp_theme_dir.join("index.php"), 'w') {|file| file.write(default_parts[:content])}
        end

        others.each do |name, parts|
          File.open(::Sphonglepress::Config.wp_theme_dir.join("header-#{name}.php"), 'w') {|file| file.write(parts[:header])}
          File.open(::Sphonglepress::Config.wp_theme_dir.join("footer-#{name}.php"), 'w') {|file| file.write(parts[:footer])}
          File.open(::Sphonglepress::Config.wp_theme_dir.join("#{name}.php"), 'w') {|file| file.write(parts[:content])}
        end
      end
      
      def files
        cmd = "cp -r #{CONFIG["middleman_dir"]}/build/*/ #{::Sphonglepress::Config.config["wp_clone_dir"]}"
        `#{cmd}`
        cmd = "cp -r #{CONFIG["middleman_dir"]}/build/stylesheets/*.css #{::Sphonglepress::Config.wp_theme_dir}/"
        `#{cmd}`
      end

      def split_file(contents)
        first = contents.split("<!-- BEGIN_BODY -->")
        second = first.last.split("<!-- END_BODY -->")
        
        {:header => first.first, :content => second.first, :footer => second.last}
      end

    end
  end
end
