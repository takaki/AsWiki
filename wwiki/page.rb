require 'obaq/htmlgen'
require 'obaq/htmlparser'

module WWiki
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
      return  f.format(tree)
    end
  end
end
  
