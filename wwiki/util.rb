require 'cgi'

module WWiki
  def WWiki::escape(s)
    return CGI::escape(s).gsub('\.','%2E')
  end
  def WWiki::unescape(s)
    return CGI::unescape
  end
  def WWiki::wikilink(name)
    return E(:a, A(:href, "#{$CGIURL}?c=v&p=#{WWiki::escape(name)}")){name}
  end
end
