# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/plugin'
require 'aswiki/util'
require 'aswiki/revlink'

module AsWiki
  class RecentPagesPlugin < Plugin
    Name = 'recentpages'
    include AsWiki::Util
    def onview(line, b, e, av)
      count = (av[1] || 100 ).to_i
      @data = {:data =>
	@repository.attrlist.sort{|a,b| b[1] <=> a[1]}[0,count].map{|l| 
	  {:plink => wikilink(l[0]), :timestamp => timestr(l[1])}
	}
      }
      load_parts
      return self
    end
  end

  class AllPagesPlugin < Plugin
    Name = 'allpages'
    include AsWiki::Util
    def onview(line, b, e, av)
      @data = {:data => @repository.namelist.sort.collect{|f| wikilink(f)},
	:total => @repository.namelist.length
      }
      load_parts
      return self
    end
  end

  class MetaPagesPlugin < Plugin
    Name = 'metapages'
    include AsWiki::Util
    def onview(line, b, e, av)
      @data = {:data => $metapages.keys.sort.collect{|k| wikilink(k)}}
      load_parts
      return self
    end
  end

  class OrphanedPagesPlugin < Plugin
    Name = 'orphanedpages'
    include AsWiki::Util
    @@run = false
    def onview(line, b, e, av)
      return nil if @@run == true
      @r = AsWiki::Repository.new('.')
      @checked = {} # i want Set ...
      @queue   = {}
      @@run = true
      markandsweep($TOPPAGENAME)
      @@run = false

      @data = {:data => (@r.namelist - @checked.keys).sort.collect{|f|
	  wikilink(f)}}
      load_parts
      return self
    end
    private 
    def markandsweep(pname)
      @checked[pname] = true
      AsWiki::Parser.new(@r.load(pname).to_s, pname).wikinames.
	uniq.each{|n|
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
	AsWiki::Parser.new(@r.load(p).to_s, p).wikinames.uniq.each{|n|
	  if n !~ /\A\w+:[A-Z]\w+(?!:)/
	    pages[n] = true
	  end
	}
      }
      plist = (pages.keys - @r.namelist).sort.delete_if {|f| 
	f =~ /[^:]+:[^:]+/
      }.collect{|f| wikilink(f)}
      @data = {:data => plist, :total => plist.length}
      load_parts
      return self
    end
  end
  class LinkPageCountPlugin < Plugin
    Name = 'linkpagecount'
    def onview(line, b, e, av)
      @r = AsWiki::Repository.new('.')
      pages = {}
      rl = RevLink.new
      rl.clear
      @r.namelist.each{|p|
	lm = AsWiki::Parser.new(@r.load(p).to_s, p).wikinames.uniq.
	  delete_if{|n| n =~ /\A\w+:[A-Z]\w+(?!:)/}
	lm.each{|n|
	  if pages.has_key?(n)
	    pages[n] << p
	  else
	    pages[n] = [p]
	  end
	}
	rl.regist(p, lm)
      }
      plist = pages.map{|k,v| 
	{
	  :linkcount => v.size,
	  :plink  => wikilink(k),
	  :pages => v.sort.map{|p| [wikilink(p),"\n"] }
	}
      }.sort{|a,b| b[:linkcount] <=> a[:linkcount]}
      @data = {:data => plist}
      load_parts
      return self
    end
    
  end

  class PluginListPlugin < Plugin
    Name = 'pluginlist'
    def onview(line, b, e, av)
      @data = {:data => 
	Plugin::PluginList.collect{|p|
	  p::Name
	}.sort
      }
      load_parts
      return self
    end
  end
end
