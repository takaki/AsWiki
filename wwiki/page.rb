# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'obaq/htmlgen'
require 'obaq/htmlparser'
require 'wwiki/util'
require 'digest/md5'

require 'amrita/template'


module WWiki
  def WWiki::editpage(name, content)
    include Obaq::HtmlGen
    data = {:title => name, :content => CGI::escapeHTML(content.to_s),
      :name => name,
      :md5sum => Digest::MD5::new(content.to_s),
      :helppage => "#{$CGIURL}?c=v;p=HelpPage",
    }
    page = WWiki::Page.new('Edit', data)
    return page
  end
  class Page
    def initialize(template ,data)
      tmplfile = File.join('template','Page', template + '.html')
      template = Obaq::HtmlParser.parse_file(tmplfile)
      @tree = template.expand(data)
    end
    attr_accessor :tree
    def to_s
      f = Obaq::HtmlGen::Formatter.new
      f.escape = false
      f.deleteln = false
      return  f.format(@tree)
      # return @tree
    end
  end
end
  
