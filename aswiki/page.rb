# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/util'
require 'digest/md5'

require 'amrita/template'
require 'amrita/merge'
# include Amrita

module AsWiki
  class Page
    def initialize(pagetype, data)
      tmplfile = File.join('template','PageBase.html')
      template = Amrita::TemplateFileWithCache[tmplfile]
      # template = Amrita::TemplateFile.new(tmplfile)
      template.expand_attr = true
      # template.use_compiler = true
      
      @str = ''
      model = { :pagedata => 
	MergeTemplateFile.new("template/Page/#{pagetype}.html") do 
	  data
	end
      }
      template.expand(@str, model)
    end
    
    def to_s
      return @str
    end
  end
end

