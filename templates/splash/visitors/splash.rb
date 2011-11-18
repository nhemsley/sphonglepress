class Visitor < Sphonglepress::Visitors::Visitor
  class << self
    #override this to visit each page
    def visit(page)
    end
    
    #run this once per import
    def once
    end
  end
end
