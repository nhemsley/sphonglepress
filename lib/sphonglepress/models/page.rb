require 'active_record'

module Sphonglepress::Models
  class Page < ActiveRecord::Base
    set_table_name :wp_posts
    set_primary_key :ID
    
    scope :pages, where(:post_type => "page")
  
    has_many :posts, :foreign_key => 'post_parent', :class_name => "Page"
    belongs_to :parent, :foreign_key => 'post_parent', :class_name => "Page"
  
  def after_initialize
      self.post_date = DateTime.now
      self.post_modified_gmt = DateTime.now
      self.post_modified = DateTime.now
      self.post_date_gmt = DateTime.now
    end
  end
end