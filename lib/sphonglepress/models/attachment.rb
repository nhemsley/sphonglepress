require 'mime/types'

module Sphonglepress::Models
  class Attachment < BasePost
    attr_accessor :file

    scope :attachments, where(:post_type => "attachment")

    before_save :do_stuff
    
    private
      
      def randomize_filename(file)
            random = rand(36**8).to_s(36)
            ext = File.extname(file)
            basename = File.basename(file, ext)
            bare_file_name = "#{basename}-#{random}#{ext}"
      end

      def do_stuff
        return unless @file
        
        self.post_type = "attachment"
        now = DateTime.now
        year = now.year
        month = now.month
        monthed_dir = now.strftime("%Y/%m")
        upload_dir = ::Sphonglepress::WP_UPLOAD_DIR.join(monthed_dir)
        bare_file_name = File.basename(@file)
        file_name = upload_dir.join(bare_file_name)
        
        file_name = upload_dir.join(bare_filename = randomize_filename(@file)) if File.exist? file_name

        FileUtils.mkdir_p upload_dir unless Dir.exist? upload_dir
        FileUtils.cp(@file, file_name)
        ext = File.extname(file)

        self.post_title = self.post_name = bare_file_name
        self.post_status = "inherit"
        self.guid = url = "/wp-content/uploads/#{monthed_dir}/#{bare_file_name}"
        self.post_mime_type = ::MIME::Types.type_for(bare_file_name).first.to_s
            
      end
  end
end