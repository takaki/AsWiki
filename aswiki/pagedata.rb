# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'aswiki/parser'

module AsWiki
  class PageData
    include AsWiki::Util
    include Amrita::ExpandByMember
    def initialize(name)
      @name = name
      @r = AsWiki::Repository.new('.')

      @title       = name
      @edit        = cgiurl([['c', 'e'], ['p', name]])
      @toppage     = cgiurl([['c', 'v'], ['p', $TOPPAGENAME]])
      @recentpages = cgiurl([['c', 'v'], ['p', 'RecentPages']])
      @allpages    = cgiurl([['c', 'v'], ['p', 'AllPages']])
      @rawpage     = cgiurl([['c', 'r'], ['p', name]])
      @historypage = cgiurl([['c', 'h'], ['p', name]])
      @diffpage    = cgiurl([['c', 'd'], ['p', name]])
      @helppage    = cgiurl([['c', 'v'], ['p', 'HelpPage']])
    end
    attr_reader :tree, :wikinames
    attr_reader :title,:edit,:recentpages,:toppage,:allpages,:rawpage,
      :diffpage,:helppage,:body, :historypage
    attr_accessor :revision, :timestamp
    def parsefile
      c = @r.load(@name)
      @timestamp = @r.mtime(@name)
      @p = AsWiki::Parser.new(c.to_s, @name)
      @wikinames = @p.wikinames
      @body = @p.tree
    end
    def parsetext(c)
      @p = AsWiki::Parser.new(c.to_s, @name)
      @wikinames = @p.wikinames
      @body = @p.tree
    end


    def lastmodified
      timestr(@timestamp)
    end
    def wikilinks
       return @p.wikinames.delete_if{|w| w =~ /:[^:]/ }.uniq.map{|l| 
 	  [l, @r.mtime(l)]}.sort{|a,b| b[1].to_i <=> a[1].to_i}.map{|l|
	{:pname => wikilink(CGI::escapeHTML(l[0]),@name) ,
	  :modified =>  modified(l[1])  }}
    end

    def logtable
      backup = AsWiki::Backup.new('.')
      logtable = backup.rlog(@name).map{|l| 
	{:revision => Amrita::e(:a, Amrita::a(:href, cgiurl([['c','h'],
							      ['p',@name],
							      ['rev',l[0]]]
							    ))){l[0]},
	  :diffline => l[2].to_s,
	  :timestamp => timestr(l[1]),
	  :tonew => Amrita::e(:a, Amrita::a(:href, 
					    cgiurl([['c', 'd'],
						     ['p', @name],
						     ['rn',0],
						     ['ro',l[0]]])
					    )){"current - #{l[0]}"},
	  :toold => l[0] != 1 ? 
	  Amrita::e(:a, Amrita::a(:href,
				  cgiurl([['c','d'],
					   ['p', @name],
					   ['rn', l[0]],
					   ['ro', l[0]-1]])
				  )){"new #{l[0]} old #{l[0]-1}"}  : 'not avail'
	}
      }
    end
  end
end
