require 'strscan'
require 'uri/common'
# require 'delegate'

require 'wwiki/scanner'

require 'obaq/htmlgen'
require 'obaq/htmlparser'

module WWiki 
  class Node< DelegateClass(Array)
    def initialize(template)
      super([])
      @tmplfile=File.join('template', template + 'Node.html')
    end
    def to_s
      template = Obaq::HtmlParser.parse_file(@tmplfile)
      data = {:data => self.to_a}
      tree = template.expand(data)
      f = Obaq::HtmlGen::Formatter.new
      f.escape = false
      f.deleteln = false
      return f.format(tree)
    end
    def parsetree
      if self == []
	return self.type
      else
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
end

