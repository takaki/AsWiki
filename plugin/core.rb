# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'aswiki/plugin'
require 'aswiki/util'


module AsWiki
  class RecentPagesPlugin < Plugin
    Name = 'recentpages'
    include AsWiki::Util
    def onview(line, b, e, av)
      count = (av[1] || 100 ).to_i
      data = {:data =>
	@repository.attrlist.sort{|a,b| b[1] <=> a[1]}.map{|l| 
	  Amrita::noescape{
	    [wikilink(l[0])," " , timestr(l[1])].to_s}
	}
      }
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
  end
  class AllPagesPlugin < Plugin
    Name = 'allpages'
    include AsWiki::Util
    def onview(line, b, e, av)
      data = {:data => @repository.namelist.sort.collect{|f| wikilink(f)},
	:total => @repository.namelist.length
      }
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
  end
  class MetaPagesPlugin < Plugin
    Name = 'metapages'
    include AsWiki::Util
    def onview(line, b, e, av)
      data = {:data => MetaPages.keys.sort.collect{|k| wikilink(k)}}
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
  end
  class OrphanedPagesPlugin < Plugin
    Name = 'orphanedpages'
    include AsWiki::Util
    @@run = false
    def onview(line, b, e, av)
      return nil if @@run == true
      @r = AsWiki::Repository.new('.')
      @checked = {} # want Set ...
      @queue   = {}
      @@run = true
      markandsweep($TOPPAGENAME)
      @@run = false

      data = {:data => (@r.namelist - @checked.keys).sort.collect{|f|
	  wikilink(f)}}
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
    private 
    def markandsweep(page)
      @checked[page] = true
      AsWiki::PageData.new(page).wikinames.collect {|l|
	expandwikiname(l,page)}.each{|n|
	if @r.exist?(n) and not @queue.key?(n) and not @checked.key?(n)
	  @queue[n] = true
	end
      }
      @queue.each_key { |l|
	@queue.delete(l)
	markandsweep(l)
      }
    end
  end
  class NotCreatedPagesPlugin < Plugin
    Name = 'notcreatedpages'
    include AsWiki::Util
    def onview(line, b, e, av)
      @r = AsWiki::Repository.new('.')
      pages = {}
      @r.namelist.each{|p|
	AsWiki::PageData.new(p).wikinames.collect{|l| 
	  expandwikiname(l,p)}.each{|n|
	  if n !~ /\A\w+:[A-Z]\w+(?!:)/
	    pages[n] = true
	  end
	}
      }
      data = {:data => (pages.keys - @r.namelist).sort.collect{|f|
	  wikilink(f)}}
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}

    end
  end
  class PluginListPlugin < Plugin
    Name = 'pluginlist'
    def onview(line, b, e, av)
      data = {:data => 
	Plugin::PluginList.collect{|p|
	  p::Name
	}.sort
      }
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
  end
end
