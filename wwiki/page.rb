require 'obaq/htmlgen'
require 'obaq/htmlparser'
require 'wwiki/util'

module WWiki
  def WWiki::editpage(name, content)
    include Obaq::HtmlGen
    data = {:title => name, :content => CGI::escapeHTML(content.to_s),
      :p => e(:input, {:type => 'hidden', :name => 'p', 
		:value => WWiki::escape(name)})
    }
    page = WWiki::Page.new('Edit', data)
    page.tree.each do |e|
      case e[:action]
      when 'save'
	e[:action] = "#{$CGIURL}"
      end
    end
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
  
