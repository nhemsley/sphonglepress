#This visitor checks for a directory in static/attachments with the same location as the relative url for the page, and attaches any files it finds
module Sphonglepress::Visitors
  class AttachmentVisitor < Visitor
    class << self
      #override this to visit each page
      def visit(page)
        url = page.url
        puts "Attachment: #{url}"
      end
      
      #run this once per import
      def once
      end
    end
  end
end