# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'strscan'
require 'uri/common'
require 'delegate'

require 'aswiki/scanner'

# require 'obaq/htmlgen'
# require 'obaq/htmlparser'
# require 'obaq/htmlcompiler'

require 'amrita/template'

module AsWiki 
  class Node
    @@template_cache = {}
    def initialize(template)
      @node = []
      tmplfile = File.join('template', 'Node', template + '.html')
      Amrita::TemplateFileWithCache::set_cache_dir('cache')
      # @template = Amrita::TemplateFileWithCache[tmplfile]
      @template = Amrita::TemplateFile.new(tmplfile)
      # @template.pre_format = true
      # @template.use_compiler = true
    end
    def <<(item)
      @node << item
    end
    def to_s
      # s = ''
      data = {:data => @node}
      # @template.expand(s, data)
      # return Amrita::noescape{s}
      return Amrita::noescape{@template.expand('', data)}
    end
  end
end

