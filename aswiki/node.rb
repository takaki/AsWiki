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
      pt.install_parts_to(PartsModule)
    end

    def initialize(template)
      @node = []

      if PartsModule.const_defined?(template)
        extend PartsModule.const_get(template)
      else
        tmplfile = File.join('template', 'Node', template + '.html')
        @template = Amrita::TemplateFile.new(tmplfile)
      end
    end

    def <<(item)
      @node << item
    end

    def expand
      if self.kind_of?(Amrita::PartsTemplate)
        to_s
      else
        data = {:data => @node}
        return @template.expand_tree(data)
      end
    end
    
    def data
      @node
    end

  end
end

