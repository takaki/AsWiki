# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'strscan'
require 'uri/common'
require 'delegate'

require 'amrita/template'

require 'aswiki/scanner'

module Amrita
  class TemplateFile
    def expand_tree(model)
      setup_template if need_update?
      context = setup_context
      return @template.expand(model, context)
    end
  end
end

module AsWiki 
  class Node
    @@template_cache = {}
    def initialize(template)
      @node = []
      tmplfile = File.join('template', 'Node', template + '.html')
      @template = Amrita::TemplateFile.new(tmplfile)
    end
    def <<(item)
      @node << item
    end
    def expand
      data = {:data => @node}
      return @template.expand_tree(data)
    end
  end
end

