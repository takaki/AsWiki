# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'aswiki/parser'

module AsWiki
  class PageData
    include AsWiki::Util
    # include Amrita::ExpandByMember
    def initialize(name)
      @name = name
      @r = AsWiki::Repository.new('.')
      c = @r.load(name)
      @p = AsWiki::Parser.new(c.to_s, name)
      @tree = @p.tree
      @wikinames = @p.wikinames

      @title = name
    end
    attr_reader :tree, :wikinames
    attr_accessor :title,:edit,:recentpages,:toppage,:allpages,:rawpage,
      :diffpage,:helppage,:contents,:lastmodified
    def wikilinks
      return Amrita::noescape{ @p.wikinames.delete_if{|w|
	  w =~ /:[^:]/ }.map{|l| expandwikiname(l, @name)}.uniq.map{|l| 
	  [l, @r.mtime(l)]}.sort{|a,b| b[1].to_i <=> a[1].to_i}.map{|l|
	  "#{wikilink(CGI::escapeHTML(l[0]),@name)}(#{modified(l[1])})\n" }}
    end
    def modified(t)
      return '-' unless t
      dif = (Time.now - t).to_i
      dif = dif / 60
      return "#{dif}m" if dif <= 60
      dif = dif / 60
      return "#{dif}h" if dif <= 24
      dif = dif / 24
      return "#{dif}d"
    end

  end
end
