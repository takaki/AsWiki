# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/repository'
require 'aswiki/node'

module Amrita
  class TemplateFile
    def expand_tree(model)
      setup_template if need_update?
      context = setup_context
      return @template.expand(model, context)
    end
  end
end

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
	# return p 
	# return p
	return v # XXX
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
#     def load_template(filename=self.type::Name)
#       tmplfile = File.join('template', 'plugin', filename + '.html')
#       template = Amrita::TemplateFileWithCache[tmplfile]
#       template.expand_attr = true
#       template.use_compiler = true
#       return template
#     end

    def load_parts(filename=self.class::Name,
		   partname=self.class::Name.capitalize)
      tmplfile = File.join('template', 'plugin', filename + '.html')
      pt = Amrita::TemplateFileWithCache[tmplfile]
      pt.expand_attr = true
      pt.use_compiler = true
      pt.install_parts_to(self.class)
      extend self.class.const_get(partname)
      # return template
    end
    attr_reader :data

  end
end
