# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'amrita/template'
require 'aswiki/pagedata'

module AsWiki
  class Page
    def initialize(pagetype, data)
      data.amulet_load(pagetype)
      tmplfile = File.join($DIR_TEMPLATE, 'PageBase.html')
      template = Amrita::TemplateFile.new(tmplfile)
#      template = Amrita::TemplateFileWithCache[tmplfile]
#      template.expand_attr = true
#      template.pre_format = true
#       template.use_compiler = true

      @str = ''
      # template.set_hint_by_sample_data(data)
      template.expand(@str, data)
    end
    
    def to_s
      return @str
    end
  end
end

