# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/util'
require 'digest/md5'

require 'amrita/template'
include Amrita

module AsWiki
  class Page
    def initialize(template ,data)
      tmplfile = File.join('template','Page', template + '.html')
      # Amrita::TemplateFileWithCache::set_cache_dir('cache')
      template = Amrita::TemplateFileWithCache[tmplfile]
      # template = Amrita::TemplateFile.new(tmplfile)
      template.expand_attr = true
      template.use_compiler = true
      # template.debug_compiler = true
      # template.prettyprint 
      @str = ''
      template.expand(@str, data)
    rescue NameError
      print $!
      print $@
    end
    
    def to_s
      return @str
    end
  end
end
  
