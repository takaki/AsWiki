# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'cgi'
require 'diff'

module WWiki
  def WWiki::escape(s)
    return CGI::escape(s).gsub('\.','%2E')
  end
  def WWiki::unescape(s)
    return CGI::unescape(s)
  end
  def WWiki::diff(a,b)
    d = Diff.new(a,b)
    f = []

    d.diffs.each{|x| 
      x.each{|e| 
	f << e
      }
    }

    c = []
    ai = 0
    bi = 0
    i = 0
    r = []
    while x = f.shift
      if x[0] == '+'
	while bi < x[1]
	  if b[bi] != a[ai]
	    raise 'not match'
	  end
	  # print "#{bi} = #{b[bi]}"
	  r << "#{bi} = #{b[bi]}"
	  ai += 1
	  bi += 1
	end
	# print  "#{bi} #{x[0]} #{x[2]}"
	r << "#{bi} #{x[0]} #{x[2]}"
	bi += 1
      elsif x[0] == '-'
	while ai < x[1]
	  if b[bi] != a[ai]
	    raise 'not match'
	  end
	  # print  "#{bi} = #{b[bi]}"
	  r << "#{bi} = #{b[bi]}"
	  ai += 1
	  bi += 1
	end
	# print  "#{bi} #{x[0]} #{x[2]}"
	r << "#{bi} #{x[0]} #{x[2]}"
	ai += 1
      else
	raise '???'
      end
    end

    while ai < a.size
      if b[bi] != a[ai]
	raise 'not match'
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
      repository = WWiki::Repository.new
      link = WWiki::escape(ename)
      if repository.exist?(ename) || name =~ /[^:]+:[^:]+/
	return Amrita::e(:a, Amrita::a(:href,"#{$CGIURL}?c=v;p=#{link}")){
	  WWiki::unescape(name)}
      else
	[WWiki::unescape(name) ,
	  Amrita::e(:a, Amrita::a(:href,"#{$CGIURL}?c=v;p=#{link}")){"?"}]
#	return Amrita::noescape{
#	  WWiki::unescape(name) + 
#	    Amrita::e(:a, Amrita::a(:href,"#{$CGIURL}?c=v;p=#{link}")){"?"}.to_s }
      end
    end
  end
end
