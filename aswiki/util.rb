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
  def AsWiki::merge(a,b, tag=true)
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
	    raise ArgumentError, 'not match 1'
	  end
	  r << diffout(b[bi], '=', tag,  bi, 'diffeql')
	  ai += 1
	  bi += 1
	end
	x[2].each{|l|
	  r << diffout(l, x[0], tag, bi, 'diffnew')
	  bi += 1
	}
      elsif x[0] == :-
	while ai < x[1]
	  if b[bi] != a[ai]
	    raise ArgumentError, 'not match 2'
	  end
	  r << diffout(b[bi], '=', tag, bi, 'diffeql')
	  ai += 1
	  bi += 1
	end
	x[2].each{|l|
	  r << diffout(l, x[0], tag, bi, 'diffold')
	  ai += 1
	}
      else
	raise ArgumentError, '???'
      end
    end

    while ai < a.size
      if b[bi] != a[ai]
	raise ArgumentError, 'not match 3'
      end
      r << diffout(b[bi], '=', tag, bi, 'diffeql')
      ai += 1
      bi += 1
    end
    return r
  end
  def AsWiki::diffout(s,sign, tag, lineno, class_)
    if tag
      return Amrita::e(:div, Amrita::a(:class, class_)){
	Amrita::e(:code){
	  "#{lineno} #{sign} #{s.chomp}"
	}
      }, "\n"
    else
      case sign.to_s
      when '='
	  return s
      when '+'
	return '+' + s
      when '-'
	return '-' + s
      else
	raise ArgumentError, sign.to_s
      end
    end
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
      link = name
      if repository.exist?(name) || name =~ /[^:]+:[^:]+/ || 
	  MetaPages.has_key?(name)
	return Amrita::e(:a, Amrita::a(:href,cgiurl([['c','v'],['p',link]]))
			 ){
	  name}
      else
	return Amrita::e(:a, Amrita::a(:href, cgiurl([['c','v'],['p',link]])),
			 Amrita::a(:class, "notexist")){
	  name + "?"}
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
    def cgiurl(arg)
      return $CGIURL + "?" +
	arg.map{|k,v| AsWiki::escape(k) + '=' + AsWiki::escape(v.to_s)}.join(';')
    end
  end
end

