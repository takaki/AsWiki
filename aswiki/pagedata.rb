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
      c = @r.load(name)
      @p = AsWiki::Parser.new(c.to_s, name)
      # @tree = @p.tree
      @wikinames = @p.wikinames
      @contents = @p.tree

      @title = name
      @edit        = "#{$CGIURL}?c=e;p=#{AsWiki::escape(name)}"
      @toppage     = "#{$CGIURL}?c=v;p=#{$TOPPAGENAME}"
      @recentpages = "#{$CGIURL}?c=v;p=RecentPages"
      @allpages    = "#{$CGIURL}?c=v;p=AllPages"
      @rawpage     = "#{$CGIURL}?c=r;p=#{AsWiki::escape(name)}"
      @diffpage    = "#{$CGIURL}?c=d;p=#{AsWiki::escape(name)}"
      @helppage    = "#{$CGIURL}?c=v;p=HelpPage"
    end
    attr_reader :tree, :wikinames
    attr_accessor :title,:edit,:recentpages,:toppage,:allpages,:rawpage,
      :diffpage,:helppage,:contents
    def lastmodified
      t = @r.mtime(@name)
      timestr(t)
    end
    def wikilinks
      return Amrita::noescape{ @p.wikinames.delete_if{|w|
	  w =~ /:[^:]/ }.map{|l| expandwikiname(l, @name)}.uniq.map{|l| 
	  [l, @r.mtime(l)]}.sort{|a,b| b[1].to_i <=> a[1].to_i}.map{|l|
	  "#{wikilink(CGI::escapeHTML(l[0]),@name)}(#{modified(l[1])})\n" }}
    end
  end
end
