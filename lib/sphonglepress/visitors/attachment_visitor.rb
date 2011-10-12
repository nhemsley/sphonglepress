#This visitor checks for a directory in static/attachments with the same location as the relative url for the page, and attaches any files it finds
module Sphonglepress::Visitors
  class AttachmentVisitor < Visitor
    def visit(page)
      attachments_dir = ::Sphonglepress::STATIC_DIR.join("attachments", page.url)
      Dir["#{attachments_dir}/*"].each do |file|
        attachment = Sphonglepress::Models::Attachment.new
        attachment.file = file
        attachment.post_parent = page.id
        attachment.save
      end
    end
    
    #run this once per import
    def once
    end
  end
end