
module Sphonglepress
  class Git
    class << self
      def clone(options)
        clone_cmd = "git clone #{options['wp_git_url']} #{options['wp_clone_dir']}"
        
        puts clone_cmd
        `#{clone_cmd}`
      end
      
      def checkout(options)
        checkout_cmd = "git --git-dir=#{options['wp_clone_dir']}/.git --work-tree=#{options['wp_clone_dir']} checkout #{options['wp_git_tag']}"
        puts checkout_cmd
        `#{checkout_cmd}`
      end
    end
  end
end