# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'strscan'
require 'uri/common'

require 'amrita/parts'
require 'aswiki/scanner'

module AsWiki 
  class Node
    module PartsModule
    end

    def Node::load_parts_template
      pt = Amrita::TemplateFileWithCache["template/Node/parts.html"]
      pt.expand_attr = true
      pt.install_parts_to(PartsModule)
    end

    def initialize(template)
      @data = []
      compact_space = false
      if PartsModule.const_defined?(template)
        extend PartsModule.const_get(template)
      else
        tmplfile = File.join('template', 'Node', template + '.html')
        @template = Amrita::TemplateFile.new(tmplfile)
      end
    end

    def <<(item)
      @data << item
      self
    end
    attr_reader :data
  end
end

