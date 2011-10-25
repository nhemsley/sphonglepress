module Sphonglepress
  class DocExporter
    
    def initialize(pages, lorem = "Lorem ipsum dolor sit amet....")
      @pages = pages
      @lorem = lorem
    end
    
    def export(output_dir)
      html = contents << headings      
      output_html = output_dir.join("site.html")
      File.open(output_html, 'w') do |f|
        f.write "<html><body>" << html << "</body></html>"
      end
      
      convert_odf_cmd = "libreoffice --headless --convert-to doc -outdir #{output_dir} #{output_html}"
      `convert_odf_cmd`
    end
    
    
    private
    
    def contents
      output = ""
      @pages.each do |page|
        output << element(page)
      end
      "<ul>" << output << "</ul>"
    end
    
    def element(page)
      output = "<li>" << page.post_title
      
      if (page.posts.length > 0)
        output << "<ul>"
        
        page.posts.each do |post|
          output << element(post)
        end
        
        output << "</ul>"
        
      end
      
      output << "</li>"
      
      output
    end
    
    def headings
      output = ""
      @pages.each do |page|
        output << heading(page)
      end
      output
    end
    
    def heading(page)
      output = "<h1>" << page.post_title << "</h1>\n<p>#{@lorem}</p>"
      
      if (page.posts.length > 0)
        page.posts.each do |post|
          output << heading(post)
        end
        
      end
      
      output
    end
    

    
  end
end