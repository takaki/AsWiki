module WWiki
  class Plugin
    PluginList = []
    PluginTable = {}
    def Plugin.inherited(sub)
      PluginList << sub
    end
    def initialize
      PluginList.each{|p|
	PluginTable[p::Name] = p
      }
    end
    def onview(line, b, e)
      l = line[0]
      l = l[1..-1]
      av = l.split
      if av[0] =='begin'
	av.shift
      end
      cmd = av[0]
      if pc = PluginTable[cmd]
	p = pc.new
	p.onview(line, b, e, av)
	return p
      else
	return line.to_s
      end
    end
    def to_s
      return @view
    end
    private
    def load_template
      tmplfile = File.join('template', 'plugin', self.type::Name + '.html')
      Obaq::HtmlParser.parse_file(tmplfile)
    end
  end
end
