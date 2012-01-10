require 'tilt'
require 'haml'
require 'ruby-debug'
require 'sphonglepress/models/page'

module Sphonglepress
  class Importer
    class << self
      def import(hash)
        structure(hash)
      end
      
      def structure(hash, parent=nil)
        i=0
        pages = []
        hash.each do |s_page|
          title = s_page["title"]
          page = nil
          if parent
            #some activerecord caching issue, can't use where
            page = parent.posts.select{|p| p.post_title == title}.first
          else
            page = Models::Page.where(:post_title => title).first
          end
          
          unless page
            if parent
              page = Models::Page.new(:post_title => title, :post_type => "page", :menu_order => i, :parent => parent)
              parent.posts << page
            else
              page = Models::Page.new(:post_title => title, :post_type => "page", :menu_order => i)
            end
            page.post_name = page.post_title.downcase.split(" ").join("-")
            page.post_date = page.post_modified = DateTime.now
            page.post_date_gmt = page.post_modified_gmt = DateTime.now.new_offset(0)
          end
          
          pages << page
          
          page_content_file = ::Sphonglepress::BUILD_DIR.join(s_page["url"][1..-1] || full_path_for_page(page)).to_s
          puts s_page["url"]
          
          if File.file?(page_content_file)
            content = split_file IO.read(page_content_file)
            page.post_content = content[:content]
          else
            puts "Couldnt find #{page_content_file} in the build directory"
          end
          
          i += 10
          if s_page["children"]
            structure(s_page["children"], page)
          end
        end
        pages
      end
      
      def persist(page)
        page.save
        puts page.post_title
        page.posts.each {|p| persist(p)}
      end

      def visit(page, visitors = Visitors::Visitor.subclasses)
        visitors.each do |v|
          visitor = v.instance
          visitor.visit(page)
          page.posts.each do |p|
            visitor.visit(p)
          end
        end
      end
    
      def split_file(contents)
        first = contents.split("<!-- BEGIN_BODY -->")
        second = first.last.split("<!-- END_BODY -->")
        
        {:header => first.first, :content => second.first, :footer => second.last}
      end
    
      def filenames_for_site(pages)
        filenames = []
        pages.each do |page|
          filenames.concat(filenames_for_page(page))
        end
        filenames
      end

      private

      # http://stackoverflow.com/questions/1939333/how-to-make-a-ruby-string-safe-for-a-filesystem
      def sanitize_filename(filename)
        filename.strip.gsub(/^.*(\\|\/)/, '').gsub(/[^0-9A-Za-z.\-]/, '-').gsub(/-+/, '-')
      end
        
      def full_path_for_page(page, path)
        (path.send(:join, *path_array_for_page(page)).to_s << ".html").downcase
      end
      
      def path_array_for_page(page)
        return [] unless page
        path_array_for_page(page.parent) << sanitize_filename(page.post_title)
      end
      
      def filenames_for_page(page)
        filenames = []
            
        filenames << full_path_for_page(page)
        page.posts.each do |child|
          filenames.concat filenames_for_page(child)
        end
        filenames
      end
      
      def images_for_page(page)
        
      end
      
    end
  end
end
