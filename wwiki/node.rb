require 'strscan'
require 'uri/common'
require 'delegate'

require 'wwiki/scanner'

require 'obaq/htmlgen'
require 'obaq/htmlparser'
require 'obaq/htmlcompiler'

module WWiki 
  class Node< DelegateClass(Array)
=begin
include Obaq
include HtmlGen
include HtmlCompiler
=end
    @@cache = {}
    def initialize(template)
      super([])
      tmplfile = File.join('template', template + 'Node.html')
      @template = Obaq::HtmlParser.parse_file(tmplfile)
    end
    def to_s
      data = {:data => self.to_a}
      tree = @template.expand(data)
      f = Obaq::HtmlGen::Formatter.new
      f.escape = false
      f.deleteln = false
      return f.format(tree)
    end
  end
end

