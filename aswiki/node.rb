# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'strscan'
require 'uri/common'

require 'amrita/parts'

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
    module PartsModule
    end

    def Node::load_parts_template
      pt = Amrita::TemplateFileWithCache["template/Node/parts.html"]
      pt.expand_attr = true
      pt.expand_attr = true
      pt.prettyprint = true
      pt.debug_compiler = true
      pt.install_parts_to(PartsModule)
    end

    def initialize(template)
      @data = []
      expand_attr = true
      compact_space = false
      if PartsModule.const_defined?(template)
        extend PartsModule.const_get(template)
	expand_attr = true
      else
        tmplfile = File.join('template', 'Node', template + '.html')
        @template = Amrita::TemplateFile.new(tmplfile)
      end
    end

    def <<(item)
      @data << item
    end
    attr_reader :data
  end
end

