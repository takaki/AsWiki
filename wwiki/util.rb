require 'cgi'

module WWiki
  def WWiki::escape(s)
    return CGI::escape(s).gsub('\.','%2E')
  end
  def WWiki::unescape(s)
    return CGI::unescape(s)
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
      link = WWiki::escape(expandwikiname(name, $pname))
      if $repository.exist?(name) || name =~ /[^:]+:[^:]+/
	return e(:a, {:href =>"#{$CGIURL}?c=v&p=#{link}"}){
	  WWiki::unescape(name)}
      else
	return WWiki::unescape(name) + 
	  e(:a, {:href, "#{$CGIURL}?c=v&p=#{link}"}){%q|?|}.to_s
      end
    end
  end
end
