# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/parser'
require "aswiki/i18n/#{$LANG}"
require 'aswiki/merge'
require 'aswiki/revlink'

module AsWiki
  class PageData
    include AsWiki::Util
    # include Amrita::ExpandByMember
    include AsWiki::I18N
    def initialize(name)
      @name = name
      @r = AsWiki::Repository.new('.')

      @title    = $TITLE + ': ' + name

      pname = @name
      @edit        = cgiurl([['c', 'e'], ['p', pname]])
      @toppage     = cgiurl([['c', 'v'], ['p', $TOPPAGENAME]])
      @recentpages = cgiurl([['c', 'v'], ['p', 'RecentPages']])
      @allpages    = cgiurl([['c', 'v'], ['p', 'AllPages']])
      @rawpage     = cgiurl([['c', 'r'], ['p', pname]])
      @historypage = cgiurl([['c', 'h'], ['p', pname]])
      @diffpage    = cgiurl([['c', 'd'], ['p', pname]])
      @helppage    = cgiurl([['c', 'v'], ['p', 'HelpPage']])
    end
    def setup
      @sb = self.clone
      @sb.sb = @sb
      extend Amrita::ExpandByMember
    end
    attr_accessor :sb
    attr_reader :edit,:recentpages,:toppage,:allpages,:rawpage,
      :diffpage,:helppage, :historypage
    attr_reader :tree, :wikinames,:name
    attr_accessor :revision, :timestamp, :body, :md5sum, :title,
      :pagetype
    attr_accessor :ebol, :eeol

    module PageParts    
    end
    def PageData::load_parts_template(pagetype)
      pt = Amrita::TemplateFileWithCache["template/Page/#{pagetype}.html"]
      pt.expand_attr = true
      pt.install_parts_to(PageParts)
    end
    def parts_extend(parts)
      data = @sb.clone
      extend PageParts.const_get(parts)
    end

    def menubar
      data = @sb.clone
      data.parts_extend('Menubar')
      return data
    end
    def pagetitle
      data = @sb.clone
      data.parts_extend('Pagetitle')
      return data
    end
    def pageheader
      data = @sb.clone
      data.parts_extend('Pageheader')
      return data
    end
    def pagebody
      data = @sb.clone
      data.parts_extend('Pagebody')
      return data
    end
    def pagefooter
      data = @sb.clone
      data.parts_extend('Pagefooter')
      return data
    end
    
    def parsefile
      c = @r.load(@name)
      @timestamp = @r.mtime(@name)
      parsetext(c.to_s)
    end
    def parsetext(c)
      @p = AsWiki::Parser.new(c.to_s, @name)
      @wikinames = @p.wikinames
      @body = @p.tree
    end

    def logtable
      backup = AsWiki::Backup.new('.')
      return backup.rlog(@name).map{|l| 
	{ :revision => {
	    :url=> cgiurl([['c','h'], ['p',@name], ['rev',l[0]]]),
	    :rev => l[0]
	  },
	  :historyraw => {
	    :url=> cgiurl([['c','hr'], ['p',@name], ['rev',l[0]]]),
	    :rev => l[0]
	  },
	  :diffline => l[2].to_s,
	  :timestamp => timestr(l[1]),
	  :tonew => {:url =>  cgiurl([['c', 'd'], ['p', @name], ['rn',0],
				       ['ro',l[0]]]),
	    :text => "current - #{l[0]}"},
	  :toold => l[0] != 1 ?  {
	    :url => cgiurl([['c','d'], ['p', @name], ['rn', l[0]],
			     ['ro', l[0]-1]]),
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

