# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'strscan'
require 'uri/common'
require 'delegate'

require 'wwiki/scanner'

require 'obaq/htmlgen'
require 'obaq/htmlparser'
require 'obaq/htmlcompiler'

# require 'amrita/template'

module WWiki 
  class Node
    def initialize(template)
      @node = []
      tmplfile = File.join('template', 'Node', template + '.html')
      @template = Obaq::HtmlParser.parse_file(tmplfile)
      # @tmpl = Amrita::TemplateFile.new(tmplfile)
    end
    def <<(item)
      @node << item
    end
    def to_s
      data = {:data => @node}
      tree = @template.expand(data)
      f = Obaq::HtmlGen::Formatter.new
      f.escape = false
      f.deleteln = false
      return f.format(tree)
    end
  end
end

