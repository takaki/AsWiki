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
    attr_reader :tree
    def <<(item)
      @node << item
    end
    def expand
      data = {:data => @node}
      @tree = @template.expand_tree(data)
    end
    def to_s
      @tree.to_s
    end
  end
end

