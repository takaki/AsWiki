# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

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
      @repository = WWiki::Repository.new
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
    def load_template(filename=self.type::Name)
      tmplfile = File.join('template', 'plugin', filename + '.html')
      Obaq::HtmlParser.parse_file(tmplfile)
    end
  end
end
