# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'aswiki/util'
require 'digest/md5'

require 'amrita/template'


module AsWiki
  def AsWiki::editpage(name, content)
    data = {:title => name, 
      # :content => CGI::escapeHTML(content.to_s),
      :content => content.to_s,
      :name => name,
      :md5sum => Digest::MD5::new(content.to_s).to_s,
      :helppage => "#{$CGIURL}?c=v;p=HelpPage",
    }
    page = AsWiki::Page.new('Edit', data)
    return page
  end
  class Page
    def initialize(template ,data)
      @str = ''
      tmplfile = File.join('template','Page', template + '.html')
      Amrita::TemplateFileWithCache::set_cache_dir('cache') # XXX
      template = Amrita::TemplateFileWithCache[tmplfile]
      template.expand_attr = true
      template.expand(@str, data)
    end
    def to_s
      return @str
    end
  end
end
  
