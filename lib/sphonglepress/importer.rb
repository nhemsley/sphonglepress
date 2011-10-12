require 'tilt'
require 'haml'

require 'sphonglepress/models/page'

module Sphonglepress
  class Importer
    class << self
      def import(hash)
        structure(hash)
      end

      def structure(hash, parent=nil)
        i=0
        sorted = hash.keys.sort {|a,b| a.split("_").first.to_i <=> b.split("_").first.to_i }
        pages = []
        page = nil
        sorted.each do |key|
          title = key[2..key.length].gsub("_", " ")
          if parent
            page = Models::Page.new(:post_title => title, :post_type => "page", :menu_order => i, :parent => parent)
            parent.posts << page
          else
            page = Models::Page.new(:post_title => title, :post_type => "page", :menu_order => i)
          end
          #puts page.post_title
          page.post_name = page.post_title.downcase.split(" ").join("-")
          page.post_date = page.post_modified = DateTime.now
          page.post_date_gmt = page.post_modified_gmt = DateTime.now.new_offset(0)
          pages << page

          page_content_file = ::Sphonglepress::STATIC_DIR.join(full_path_for_page(page)).to_s << ".html.haml"

          begin 
            if File.exist?(page_content_file)
              #puts "found #{page_content_file}"
              page.post_content = Tilt.new(page_content_file, :ugly => true).render
            else
              puts "Couldnt find #{page_content_file} in the static directory"
            end
          rescue Haml::SyntaxError => e
            puts "Error on line #{e.line}: #{e.message}"
            raise
          end
          
          i += 10
          

          if hash[key].is_a? Hash
            structure(hash[key], page)
          end
        end
        pages
      end

      def persist(page)
        page.save
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
        filename.strip.gsub(/^.*(\\|\/)/, '').gsub(/[^0-9A-Za-z.\-]/, '-')
      end
        
      def full_path_for_page(page)
        return "" unless page
        path = full_path_for_page(page.parent)
        join = path.length > 0 ? "_" : ""
        return "#{path << join}" << "#{sanitize_filename(page.post_title)}"
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