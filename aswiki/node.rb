# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'strscan'
require 'uri/common'

# require 'amrita/parts'
require 'amrita/amulet'

require 'aswiki/scanner'


module AsWiki 
  class Node
    def Node::parts
      @pt = Amrita::TemplateFileWithCache[File.join($DIR_TEMPLATE,'Node.html')]
      @pt.define_amulet(:Dl=>Node, :Em=>Node, 
			:H2=>Node, :H3=>Node, :H4=>Node, :H5=>Node, :H6=>Node,
			:Ol=>Node, :Paragraph=>Node, 
			:Strong=>Node, :Table=>Node, :Root=>Node,  
			:Textline=>Node, :Plaintext=>Node, 
			:Element=>Node, :Ul=>Node, :Hr=>Node, :Url=>Node, 
			:Moinhref=>Node, :MoinhrefImg=>Node, :Br=>Node,
			:WikiNameNE=>Node, :WikiName=>Node,
			:Diffout=>Node,
			:pre=>Node
			)
      return @pt
    end


    include Amrita::Amulet
    def initialize(data=[])
      @data = data
    end
    attr_reader :data
  end
end

