# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'cgi'
require 'algorithm/diff'

module AsWiki
  def AsWiki::escape(s)
    s # XXX ??? ruby's bug ???
    return CGI::escape(s).gsub('\.','%2E')
  end
  def AsWiki::unescape(s)
    return CGI::unescape(s)
  end
  def AsWiki::redirectpage(cgi, url)
    cgi.out({'Status' => '302 REDIRECT',
	      'Location' => url}){Amrita::e(:a,Amrita::a(:href, url)){url}.to_s}
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
      return Node.new('Diffout') << { :class => class_, 
	:text =>  "#{lineno} #{sign} #{s.chomp}"}
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
    def pathexpand(path)
      ret = []
      path.each { |k| 
	if (k == '.') ; next ; end
	if (k == '..'); ret.pop; next; end
	ret <<  k
      }
      return ret
    end

    def expandwikiname(wikiname, base='')
      bcur = []
      wcur = []
      bpath = base
      wpath = wikiname

      if base.index(%r|//+|)
	t = base.split('//')
	bcur  = t[0...-1]
	bpath = t[-1]
      end
      if wikiname.index('//')
	t = wikiname.split('//')
	wcur  = t[0...-1]
	wpath = t[-1]
      end
      
      case wcur[0]
      when nil
	cur = bcur
      when ''
	# cur = wcur.join('//')
	wcur.shift
	cur = wcur
      else 
	cur = pathexpand(bcur + wcur)
      end
      if wpath.index('.') 
	n = ((wpath[0,1] == '.' ? bpath + '/' : '') + wpath).split('/')
	p = pathexpand(n)
	fullpath = p.join('/')
      else
	fullpath = wpath
      end

      return (cur.push(fullpath)).join('//')
    end
    def wikilink(name, base='')
      repository = AsWiki::Repository.new
      link  = name
      elink = expandwikiname(link, base)
      if repository.exist?(elink) || elink =~ /[^:]+:[^:]+/ || 
	  $metapages.has_key?(elink)
	return Node.new('WikiName') << {
	  :url => cgiurl([],elink),
	  :text => name}
      else
	return Node.new('WikiNameNE') << { 
	  :url => cgiurl([], elink),
	  :text => name }
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
    def cgiurl(arg, path=nil)
      return $CGIURL + (path and ("/" + path.split('/').collect{|f| 
      AsWiki::escape(f)}.join('/')) ).to_s + 
	(arg.empty? ? '' : "?" + 
	 arg.map{|k,v| AsWiki::escape(k) + '=' + AsWiki::escape(v.to_s)}.join(';'))
    end
  end
end

