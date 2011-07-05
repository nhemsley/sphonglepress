module Sphonglepress::Models
  class BasePost < ActiveRecord::Base
    set_table_name :wp_posts
    set_primary_key :ID
    
    has_many :children, :foreign_key => 'post_parent', :class_name => self.class
    belongs_to :parent, :foreign_key => 'post_parent', :class_name => self.class
    
    after_initialize :set_dates
    
    private
    def set_dates
      self.post_date = DateTime.now
      self.post_modified_gmt = DateTime.now
      self.post_modified = DateTime.now
      self.post_date_gmt = DateTime.now
    end
  end
end