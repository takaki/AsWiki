# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'strscan'
require 'uri/common'
require 'delegate'

require 'aswiki/scanner'

# require 'obaq/htmlgen'
# require 'obaq/htmlparser'
# require 'obaq/htmlcompiler'

require 'amrita/template'

module AsWiki 
  class Node
    def initialize(template)
      @node = []
      tmplfile = File.join('template', 'Node', template + '.html')
      # @template = Obaq::HtmlParser.parse_file(tmplfile)
      @template = Amrita::TemplateFile.new(tmplfile)
    end
    def <<(item)
      @node << item
    end
    def to_s
      s = ''
      data = {:data => @node}
      @template.expand(s, data)
      return Amrita::noescape{s}
    end
  end
end

