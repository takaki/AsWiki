require 'strscan'
require 'uri/common'
# require 'delegate'

require 'wwiki/scanner'

require 'obaq/htmlgen'
require 'obaq/htmlparser'

module WWiki 
  # class Node< SimpleDelegator
  class Node< DelegateClass(Array)
    def initialize
      super([])
    end
    def to_s
      tmplfile = File.join('template',self.type.to_s.split('::')[-1] + '.html')
      template = Obaq::HtmlParser.parse_file(tmplfile)
      data = {:list => self.to_a}
      tree = template.expand(data)
      f = Obaq::HtmlGen::Formatter.new
      f.escape = false
      f.deleteln = false
      return f.format(tree).gsub("\n+","\n")
    end
    def parsetree
      if self == []
	return self.type
      else
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

  class ParagraphNode < Node
  end
  class TextlineNode < Node
    def to_s
      return self.to_a.to_s
    end
  end
  class TextNode < Node
    def to_s
      return self.to_a.to_s
    end
  end
  class RootNode < Node
  end
  class EmNode < Node
  end
  class StrongNode < Node
  end
  class WordNode < Node
  end
  class OlNode <Node
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

