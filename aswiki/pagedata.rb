# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/parser'
require "aswiki/i18n/#{$LANG}"
# require 'delegate'

module AsWiki
  class PageParts
    include AsWiki::I18N
    module PartsModule
    end
    def PageParts::load_parts_template(pagetype)
      pt = Amrita::TemplateFileWithCache["template/Page/#{pagetype}.html"]
      pt.expand_attr = true
      pt.install_parts_to(PartsModule)
    end
    def initialize(pagedata, template)
      extend PartsModule.const_get(template)
      @pd = pagedata
      # super(pagedata)
    end
  end

  class PageData
    class MenuBar < PageParts
      include I18N
      def initialize(pd)
	super(pd, 'MenuBar')
	pname = pd.name
	@edit        = cgiurl([['c', 'e'], ['p', pname]])
	@toppage     = cgiurl([['c', 'v'], ['p', $TOPPAGENAME]])
	@recentpages = cgiurl([['c', 'v'], ['p', 'RecentPages']])
	@allpages    = cgiurl([['c', 'v'], ['p', 'AllPages']])
	@rawpage     = cgiurl([['c', 'r'], ['p', pname]])
	@historypage = cgiurl([['c', 'h'], ['p', pname]])
	@diffpage    = cgiurl([['c', 'd'], ['p', pname]])
	@helppage    = cgiurl([['c', 'v'], ['p', 'HelpPage']])
      end
      attr_reader :edit,:recentpages,:toppage,:allpages,:rawpage,
	:diffpage,:helppage, :historypage
    end
    class PageTitle < PageParts
      def initialize(pd)
	super(pd, 'PageTitle')
      end 
      def title
	$TITLE + ': ' + @pd.title
      end
      def revision 
	@pd.revision
      end
      def lastmodified
	# timestr(@pd.timestamp)
	@pd.lastmodified
      end
    end
      
    class PageHeader < PageParts
      def initialize(pd)
	super(pd, 'PageHeader')
      end 
      def tableofcontents
	@pd.tableofcontents
      end
      def logtable
	@name = @pd.name
	
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
    end


    class PageBody < PageParts
      def initialize(pd)
	super(pd, 'PageBody')
      end
      
      def body
	@pd.body
      end
      def name
	@pd.name
      end
      def md5sum
	@pd.md5sum
      end
    end

    class PageFooter < PageParts
      def initialize(pd)
	super(pd, 'PageFooter')
      end
      def lastmodified
	@pd.lastmodified
	# timestr(@pd.timestamp)
      end
      def wikilinks
	@pd.wikilinks
      end
    end

    include AsWiki::Util
    include Amrita::ExpandByMember
    include AsWiki::I18N


    def PageData::load_parts_template(pagetype)
      pt = Amrita::TemplateFileWithCache["template/Page/#{pagetype}.html"]
      pt.expand_attr = true
      pt.install_parts_to(PartsModule)
    end

    def initialize(name)
      @name = name
      @r = AsWiki::Repository.new('.')

      @title    = name
    end
    attr_reader :tree, :wikinames,:name
    attr_accessor :revision, :timestamp, :body, :md5sum, :title,
      :pagetype
    
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

    def menubar
      MenuBar.new(self)
    end
    def pagetitle
      PageTitle.new(self)
    end
    def pageheader
      PageHeader.new(self)
    end
    def pagebody
      PageBody.new(self)
    end
    def pagefooter
      PageFooter.new(self)
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
	{:pname => wikilink(CGI::escapeHTML(l[0]), @name) ,
	  :modified =>  modified(l[1])  }}
    end

  end
end

