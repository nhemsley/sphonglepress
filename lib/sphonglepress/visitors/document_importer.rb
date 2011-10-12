require 'nokogiri'
require 'haml/html'
require 'fileutils'

#This visitor checks for a site.odt & the config file ("import_from_site_document")
# and attempts to import thi into the site, based on position of h1s
module Sphonglepress::Visitors
  class DocumentImporter #< Visitor
    include Singleton

    #override this to visit each page
    def visit(page)
      debugger
      found = @segments[page.post_title]
      return unless found
      #page.post_content = found
      file = ::Sphonglepress::STATIC_DIR.join("from_document", full_path_for_page(page) << ".html.haml")
      FileUtils.mkdir_p(file.dirname) unless Dir.exist? file.dirname
      File.open(file, 'w') do |f|
        f.write Haml::HTML.new(found, :xhtml => true).render
      end
      
    end
    
    #run this once per import
    def once
      convert
      source_doc = Sphonglepress::STATIC_DIR.join("document", "site.html")
      cleaned = clean(source_doc)
      @segments = segment cleaned
    end
    
    def clean(doc)
      
      require ::Sphonglepress::App::APP_DIR.join("vendor", "html_cleaner")
      opts = {
        :remove_attrs => %w(style width height cellpadding cellspacing valign halign),
        :remove_tags => %w(font style meta b),
        :remove_nested_empty_tags => [%w(p br)]
      }
      
      cleaner = HTMLCleaner.new(IO.read(doc), opts)
      File.open(Sphonglepress::STATIC_DIR.join("document", "site.cleaned.html"), 'w') do |f|
        f.write(cleaner.render)
      end
      cleaner.render
    end
    
    def segment(doc)
      segments = {}
      doc = Nokogiri::HTML(doc)
      headers = doc.css('h1')
      headers.each_with_index do |h, index|
        heading = clean_header(h)
        content = content_until(h, headers[index+1])
        segments[heading] = content.chomp.chomp("\n")
      end
      segments
    end
    
    def content_until(from, to)
      siblings = [from.next_sibling]
      while((siblings.last.next_sibling != to) rescue false)
        siblings << siblings.last.next_sibling
      end
      siblings.inject("") {|m, s| m << s.to_s}
    end
    
    def clean_header(tag)
      tag.inner_html.chomp.gsub("\n", " ").gsub(/ +/, " ").chomp(":").gsub(/^[0-9]*\./, "").strip rescue ""
    end
    
    def convert
      source_dir = Sphonglepress::STATIC_DIR.join("document")
      source_doc = source_dir.join("site.odt")
      puts "SOURCE DOC: #{source_doc}" if File.exist? source_doc
      cmd = "libreoffice  -headless -convert-to html -outdir #{source_dir} #{source_doc}"
      `#{cmd}`
    end
    
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
  end
end