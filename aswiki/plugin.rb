# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'aswiki/repository'
require 'aswiki/node'

module AsWiki
  class Plugin
    PluginList = []
    PluginTable = {}
    PluginTableByType = {}
    def Plugin.inherited(sub)
      PluginList << sub
      PluginTableByType[sub.to_s] = sub
    end
    def initialize(name)
      @name = name
      PluginList.each{|p|
	PluginTable[p::Name] = p
      }
      @repository = AsWiki::Repository.new
      @view = ''
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
	p = pc.new(@name)
	v = p.onview(line, b, e, av)
	return v
	# return p
      else
	return line.to_s
      end
    end
#    def to_s
#      STDERR.puts @view.type
#      return @view
#    end
    private
    def load_template(filename=self.type::Name)
      tmplfile = File.join('template', 'plugin', filename + '.html')
      tmpl = Amrita::TemplateFile.new(tmplfile)
      tmpl.expand_attr = true
      return tmpl
    end
  end
end
