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
	  # print "#{bi} = #{b[bi]}"
	  r << "#{bi} = #{b[bi]}"
	  ai += 1
	  bi += 1
	end
	# print  "#{bi} #{x[0]} #{x[2]}"
	x[2].each{|l|
	  r << "#{bi} #{x[0]} #{l}"
	  bi += 1
	}
      elsif x[0] == :-
	while ai < x[1]
	  if b[bi] != a[ai]
	    raise 'not match 2'
	  end
	  # print  "#{bi} = #{b[bi]}"
	  r << "#{bi} = #{b[bi]}"
	  ai += 1
	  bi += 1
	end
	# print  "#{bi} #{x[0]} #{x[2]}"
	x[2].each{|l|
	  r << "#{bi} #{x[0]} #{l}"
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
      # print  "#{bi} = #{b[bi]}\n"
      r << "#{bi} = #{b[bi]}"
      ai += 1
      bi += 1
    end
    return r
  end
  
  module Util
    def expandwikiname(wikiname, base)
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
    def wikilink(name)
      ename = expandwikiname(name, $pname)
      repository = AsWiki::Repository.new
      link = AsWiki::escape(ename)
      if repository.exist?(ename) || name =~ /[^:]+:[^:]+/
	return Amrita::e(:a, Amrita::a(:href,"#{$CGIURL}?c=v;p=#{link}")){
	  AsWiki::unescape(name)}
      else
	[AsWiki::unescape(name) ,
	  Amrita::e(:a, Amrita::a(:href,"#{$CGIURL}?c=v;p=#{link}")){"?"}]
      end
    end
  end
end
