require 'cgi'

module WWiki
  def WWiki::escape(s)
    return CGI::escape(s).gsub('\.','%2E')
  end
  def WWiki::unescape(s)
    return CGI::unescape(s)
  end
  module Util
    def wikilink(name)
      if $repository.exist?(name)
	return e(:a, {:href =>"#{$CGIURL}?c=v&p=#{WWiki::escape(name)}"}){
	  WWiki::unescape(name)}
      else
	return WWiki::unescape(name) + 
	  e(:a, {:href, "#{$CGIURL}?c=v&p=#{WWiki::escape(name)}"}){%q|?|}.to_s
      end
    end
  end
end
