# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/util'
require 'digest/md5'

require 'amrita/template'
# include Amrita

module AsWiki
  class Page
    def initialize(pagetype, data)
      PageParts::load_parts_template(pagetype)
      tmplfile = File.join('template','PageBase.html')
      template = Amrita::TemplateFileWithCache[tmplfile]
      template.expand_attr = true
      template.use_compiler = true
      
      @str = ''
      template.expand(@str, data)
    end
    
    def to_s
      return @str
    end
  end
end

