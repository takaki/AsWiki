# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'cgi'
require 'algorithm/diff'

module AsWiki
  def AsWiki::escape(s)
    return CGI::escape(s).gsub('\.','%2E')
  end
  def AsWiki::unescape(s)
    return CGI::unescape(s)
  end
  def AsWiki::diff(a,b)
    f = Diff::diff(a,b)

    c = []
    ai = 0
    bi = 0
    i = 0
    r = []
    while x = f.shift
      if x[0] == :+
	while bi < x[1]
	  if b[bi] != a[ai]
	    raise 'not match 1'
	  end
	  r << Amrita::e(:div){
	    Amrita::e(:code){"#{bi} = #{b[bi]}".chomp}} << "\n"
	  ai += 1
	  bi += 1
	end
	x[2].each{|l|
	  r << Amrita::e(:div, Amrita::a(:class,'diffnew')){
	    Amrita::e(:code){"#{bi} #{x[0]} #{l}".chomp}} << "\n"
	  bi += 1
	}
      elsif x[0] == :-
	while ai < x[1]
	  if b[bi] != a[ai]
	    raise 'not match 2'
	  end
	  r << Amrita::e(:div){
	    Amrita::e(:code){"#{bi} = #{b[bi]}".chomp}} << "\n"
	  ai += 1
	  bi += 1
	end
	x[2].each{|l|
	  r << Amrita::e(:div, Amrita::a(:class,'diffold')){
	    Amrita::e(:code){"#{bi} #{x[0]} #{l}".chomp}} << "\n"
	  ai += 1
	}
      else
	raise '???'
      end
    end

    while ai < a.size
      if b[bi] != a[ai]
	raise 'not match 3'
      end
      r << Amrita::e(:div){Amrita::e(:code){"#{bi} = #{b[bi]}".chomp}} << "\n"
      ai += 1
      bi += 1
    end
    return r
  end
  def diffout(s, class_=nil)
    [Amrita::e(:div, (class_ ? Amrita::a(:class, class_) : nil)){
	Amrita::e(:code){
	  s.chomp
	}
      }, "\n"]
  end

  module Util
    def expandwikiname(wikiname, base='')
      # return wikiname # XXX
      if wikiname.index('.') 
	p = []
	n = ((wikiname[0,1] == '.' ? base + '/' : '') + wikiname).split('/')
	n.each { |k| 
	  if (k == '.') ; next ; end
	  if (k == '..'); p.pop; next; end
	  p <<  k
	}
	return  p.join('/');
      else
	return wikiname
      end
    end
    def wikilink(name, base='')
      repository = AsWiki::Repository.new
      link = AsWiki::escape(name)
      if repository.exist?(name) || name =~ /[^:]+:[^:]+/ || 
	  MetaPages.has_key?(name)
	return Amrita::e(:a, Amrita::a(:href,"#{$CGIURL}?c=v;p=#{link}")
			 ){
	  AsWiki::unescape(name)}
      else
	return Amrita::e(:a, Amrita::a(:href,"#{$CGIURL}?c=v;p=#{link}"),
			 Amrita::a(:class, "nonexistent")){
	  AsWiki::unescape(name) + "?"}
      end
    end
    def timestr(t)
      t.strftime($TIMEFORMAT) + " (#{modified(t)}) "
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
