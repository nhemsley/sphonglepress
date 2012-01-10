module Sphonglepress::Visitors
  class Visitor
    include Singleton
    
    #override this to visit each page
    def visit(page)
    end
    
    #run this once per import
    def before
    end
    
    def after
      
    end
    
    alias :once :before
  end
end