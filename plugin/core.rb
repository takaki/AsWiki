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
	  Amrita::noescape{[wikilink(l[0])," " ,
	      l[1].strftime("%F %T %z")].to_s}}
      }
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
  end
  class AllPagesPlugin < Plugin
    Name = 'allpages'
    include AsWiki::Util
    def onview(line, b, e, av)
      data = {:data => @repository.namelist.sort.collect{|f| wikilink(f)}}
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
  end
  class MetaPagesPlugin < Plugin
    Name = 'metapages'
    include AsWiki::Util
    def onview(line, b, e, av)
      data = {:data => MetaPages.collect{|k,v| wikilink(k)}}
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
      pname = $pname
      $pname = $TOPPAGENAME # XXX
      markandsweep($TOPPAGENAME)
      $pname = pname # XXX
      @@run = false

      data = {:data => (@r.namelist - @checked.keys).sort.collect{|f|
	  wikilink(f)}}
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
    private 
    def markandsweep(page)
      STDERR.puts '0',page
      @checked[page] = true
      AsWiki::Parser.new(@r.load(page).to_s).wikinames.each {|l|
	STDERR.puts '1', l
	if @r.exist?(l) and not @queue.key?(l) and not @checked.key?(l)
	  @queue[l] = true
	end
      }
      @queue.each_key { |l|
	STDERR.puts '2', l
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
      pname = $pname
      $pname = $TOPPAGENAME
      @r.namelist.each{|p|
	AsWiki::Parser.new(@r.load(p).to_s).wikinames.each{|l|
	  if l !~ /\A\w+:[A-Z]\w+(?!:)/
	    pages[l] = true
	  end
	}
      }
      $pname = pname
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
