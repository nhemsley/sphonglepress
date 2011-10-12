module Sphonglepress::Visitors
  class Visitor
    include Singleton
    
    #override this to visit each page
    def visit(page)
    end
    
    #run this once per import
    def once
    end
  end
end