require 'obaq/htmlgen'
require 'obaq/htmlparser'

module WWiki
  class Page
    def initialize(template ,data)
      @template = template
      @data = data
    end
    def to_s
      tmplfile = File.join('template',@template + '.html')
      template = Obaq::HtmlParser.parse_file(tmplfile)
      tree = template.expand(@data)
      f = Obaq::HtmlGen::Formatter.new
      f.escape = false
      f.deleteln = false
      return  f.format(tree)
    end
  end
end
  
