# Copyritght (c) 2003 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/plugin'

module AsWiki
  # mknmz -U -t text/plain -a -k -L ja ../text
  class SearchPlugin < Plugin
    Name = 'search'
    include I18N
    include Util
    def onview(line, b, e, av=[])
      require 'search/namazu'
      word = ''
      if av[1..-1].empty?
	word = CGI.new.value('word')[0]
      else
	word = av.join(' ')
      end
      url = []
      if word
	res = Search::Namazu::search(word, 'namazu')
	url = res.result.sort{|a,b| a.rank <=> b.rank}.collect{|r|
	  page = CGI::unescape(File.basename(r.fields['uri']))
	  {:page => page, :url => cgiurl([],page)}
	}
      end
      @data = {
	:word   => word,
	:result => url,
      }
      load_parts	
      return self
    end
  end
end
