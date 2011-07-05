module Sphonglepress::Models
  class Attachment < BasePost
    attr_accessor :file

    scope :attachments, where(:post_type => "attachment")

    before_save :do_stuff
    
    private
      
      def do_stuff
        return if !@file
            self.post_type = "attachment"
            now = DateTime.now
            year = now.year
            month = now.month
            random = rand(36**8).to_s(36)
            ext = File.extname(@file)
            monthed_dir = now.strftime("%Y/%m")
            upload_dir = ::Sphonglepress::WP_UPLOAD_DIR.join(monthed_dir)
            bare_file_name = "#{random}#{ext}"
            
            self.post_title = self.post_name = bare_file_name
            self.post_status = "inherit"
            self.guid = url = "/wp-content/uploads/#{monthed_dir}/#{bare_file_name}"
            self.post_mime_type = "image/jpeg"
            file_name = upload_dir.join(bare_file_name)
            FileUtils.mkdir_p upload_dir
            FileUtils.cp(@file, file_name)
        end
      end
end