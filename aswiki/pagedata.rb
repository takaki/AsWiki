# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/parser'
require "aswiki/i18n/#{$LANG}"
require 'aswiki/util'
require 'aswiki/revlink'

require 'amrita/amulet'

module AsWiki
  class PageData
    include AsWiki::Util
    include AsWiki::I18N
    include Amrita::ExpandByMember

    def initialize(name)
      @name = name
      @r = AsWiki::Repository.new

      @title    = $TITLE + ': ' + name

      pname = @name
      @edit        = cgiurl([['c', 'e']], pname)
      @toppage     = cgiurl([['c', 'v']], $TOPPAGENAME)
      @recentpages = cgiurl([['c', 'v']], 'RecentPages')
      @allpages    = cgiurl([['c', 'v']], 'AllPages')
      @rawpage     = cgiurl([['c', 'r']], pname)
      @historypage = cgiurl([['c', 'h']], pname)
      @diffpage    = cgiurl([['c', 'd']], pname)
      @helppage    = cgiurl([['c', 'v']], 'HelpPage')
      @searchpage  = cgiurl([], 'SearchPage')
      # @csspath = $CGIURLdefault.css

      # @theme = { :href => File.dirname($CGIURL) + "/default.css" }
      @theme = { :href => File.dirname($CGIURL) +  "/default.css" }
    end

    def amulet_load(pagetype)
      # @am = Amrita::TemplateFileWithCache[File.join($DIR_TEMPLATE,"Page/#{pagetype}.html")]
      @am = Amrita::TemplateFile.new(File.join($DIR_TEMPLATE,"Page/#{pagetype}.html"))
      @am.define_amulet(:Menubar, :Pagetitle, :Pageheader, :Pagebody, :Pagefooter)
    end

    attr_reader :searchpage
    attr_reader :theme
    attr_accessor :sb
    attr_reader :edit,:recentpages,:toppage,:allpages,:rawpage,
      :diffpage,:helppage, :historypage
    attr_reader :tree, :wikinames,:name
    attr_accessor :revision, :timestamp, :body, :md5sum, :title,
      :pagetype
    attr_accessor :ebol, :eeol

    def menubar
      return @am.create_amulet(:Menubar, self)
    end
    def pagetitle
      return @am.create_amulet(:Pagetitle, self)
    end
    def pageheader
      return @am.create_amulet(:Pageheader, self)
    end
    def pagebody
      return @am.create_amulet(:Pagebody, self)
    end
    def pagefooter
      return @am.create_amulet(:Pagefooter, self)
    end
    
    def parsefile
      # c = @r.load(@name)
      @timestamp = @r.mtime(@name)
      @p = AsWiki::Parser.new(FileScanner[@name], @name)
      @wikinames = @p.wikinames
      @body = @p.tree

    end
    def parsetext(c)
      @p = AsWiki::Parser.new(Scanner.new(c.to_s), @name)
      @wikinames = @p.wikinames
      @body = @p.tree
    end

    def logtable
      backup = AsWiki::Backup.new
      return backup.rlog(@name).map{|l| 
	{ :revision => {
	    :url=> cgiurl([['c','h'], ['rev',l[0]]],@name),
	    :rev => l[0]
	  },
	  :historyraw => {
	    :url=> cgiurl([['c','hr'], ['rev',l[0]]],@name),
	    :rev => l[0]
	  },
	  :diffline => l[2].to_s,
	  :timestamp => timestr(l[1]),
	  :tonew => {:url =>  cgiurl([['c', 'd'], ['rn',0],
				       ['ro',l[0]]], @name),
	    :text => "current - #{l[0]}"},
	  :toold => l[0] != 1 ?  {
	    :url => cgiurl([['c','d'], ['rn', l[0]],
			     ['ro', l[0]-1]], @name),
	    :text => "new #{l[0]} old #{l[0]-1}" }  : 'not avail'
	}
      }
    end

    def lastmodified
      timestr(timestamp)
    end

    def tableofcontents
      @p.tocdata 
    end
    def wikilinks
      @p.wikinames.delete_if{|w| w =~ /:[^:]/ }.uniq.map{|l| 
	[l, @r.mtime(l)]}.sort{|a,b| b[1].to_i <=> a[1].to_i}.map{|l|
	{ # :pname => wikilink(CGI::escapeHTML(l[0]), @name) ,
	  :pname => wikilink(CGI::escapeHTML(l[0])),  #, @name) ,
	  :modified =>  modified(l[1])  }}
    end
    def revlinks
      RevLink.new.list(@name).map{|l| 
	[l, @r.mtime(l)]}.sort{|a,b| b[1].to_i <=> a[1].to_i
      }.map{|l|
	{
	  :pname => wikilink(CGI::escapeHTML(l[0])),  #, @name) ,
	  :modified =>  modified(l[1])
	}
      }
    end
  end
end

