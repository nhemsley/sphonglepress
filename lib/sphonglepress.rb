$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "sphonglepress/git.rb"

module Sphonglepress
  VERSION = '0.0.1'
  
  class App < Thor
    desc "init", "Initialize wordpress directory"
    method_options :wp_git_url => :string, :wp_git_tag => :string, :wp_clone_dir => :string
    def init
      opts = DEFAULT_OPTIONS.merge options
      p opts      
      Git.clone(opts)
      Git.checkout(opts)
    end
    
    DEFAULT_OPTIONS = {"wp_git_url" => "https://github.com/dxw/wordpress", "wp_git_tag" => "v3.1.3", "wp_clone_dir" => "wordpress"}
  end
end