require 'strscan'
require 'uri/common'
require 'delegate'

require 'wwiki/scanner'

module WWiki
  class Node < SimpleDelegator
    def initialize
      super([])
    end
    def parsetree
      if self == []
	return self.type
      else
	# p self
	# p self.select{|n| n.is_a? Node }
	# return {self.type => self.select{|n| n.is_a? Node }.map{|n| n.parsetree}}
	return {self.type => self.map{|n| 
	    if n.is_a? Node
	      n.parsetree
	    else
	      n
	    end
	  }
	}

      end
    end
  end

  class NormaltextNode < Node
  end
  class TextlineNode < Node
  end
  class TextNode < Node
  end
  class RootNode < Node
  end
  class EmNode < Node
  end
  class StrongNode < Node
  end
  class WordNode < Node
  end
  class UlNode <Node
  end
  class LiNode <Node
  end
  class HrNode < Node
  end
  class WikinameNode < Node
  end
end

