module Sphonglepress
  class Export
    class << self
      

      def headers_footers
        build_dir = ::Sphonglepress::Config.config["middleman_dir"].join("build")
        puts build_dir
        
        default_file = build_dir.join("default.html")
        default_parts = split_file(IO.read(default_file))
        
        other_files = Dir["#{build_dir}/*.html"]. #without default.html
                    reject {|file| Pathname.new(file).basename.to_s == "default.html"}
        
        others = {}
        other_files.each do |file|
          others[File.basename(file, '.*')] = split_file(IO.read(file))
        end
        
        File.open(::Sphonglepress::Config.wp_theme_dir.join("header.php"), 'w') {|file| file.write(default_parts[:header])}
        File.open(::Sphonglepress::Config.wp_theme_dir.join("footer.php"), 'w') {|file| file.write(default_parts[:footer])}
        
        others.each do |name, parts|
          File.open(::Sphonglepress::Config.wp_theme_dir.join("header-#{name}.php"), 'w') {|file| file.write(parts[:header])}
          File.open(::Sphonglepress::Config.wp_theme_dir.join("footer-#{name}.php"), 'w') {|file| file.write(parts[:footer])}
          File.open(::Sphonglepress::Config.wp_theme_dir.join("#{name}.php"), 'w') {|file| file.write(parts[:content])}
        end
      end

      def split_file(contents)
        first = contents.split("<!-- BEGIN_BODY -->")
        second = first.last.split("<!-- END_BODY -->")
        
        {:header => first.first, :content => second.first, :footer => second.last}
      end

    end
  end
end