require 'strscan'
require 'uri/common'
require 'delegate'

require 'wwiki/scanner'

require 'obaq/htmlgen'
require 'obaq/htmlparser'
require 'obaq/htmlcompiler'

module WWiki 
  class Node # < DelegateClass(Array)
    # class Node  < DelegateClass(Array)
    # include Obaq::HtmlCompiler
    def initialize(template)
      @node = []
      # super([])
      tmplfile = File.join('template', 'Node', template + '.html')
      @template = Obaq::HtmlParser.parse_file(tmplfile)
    end
    def <<(item)
      @node << item
    end
    def to_s
      # data = {:data => Obaq::noescape{@node.to_s}}
      # data = {:data => @node}
      data = {:data => @node}
      tree = @template.expand(data)
      f = Obaq::HtmlGen::Formatter.new
      f.escape = false
      f.deleteln = false
      return f.format(tree)
    end
  end
end

