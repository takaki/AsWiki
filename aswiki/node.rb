# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'strscan'
require 'uri/common'

# require 'amrita/parts'
require 'amrita/amulet'

require 'aswiki/scanner'


module AsWiki 
  class NodeFactory
    def initialize
      @pt = Amrita::TemplateFileWithCache[File.join($DIR_TEMPLATE,'Node.html')]
      @pt.define_amulet(:Dl, :Em, 
			:H2, :H3, :H4, :H5, :H6,
			:Ol, :Paragraph, 
			:Strong, :Table, :Root,  
			:Textline, :Plaintext, 
			:Element, :Ul, :Hr, :Url, 
			:Moinhfer, :MoinhrefImg, :Br)
    end
    def get_node(id, data)
      @pt.create_amulte(:id, *data)
    end
  end
  $nf = NodeFactory.new
  class Node
    include Amrita::Amulet
    def initialize(template)
      @data = []
      # compact_space = false
      # extend PartsModule.const_get(template)
    end

    def <<(item)
      @data << item
      self
    end
    attr_reader :data
  end
end

