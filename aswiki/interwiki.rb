# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/repository'

module AsWiki
  class InterWikiDB
    def initialize
      @url = {}
      @code = {}
      repository = AsWiki::Repository.new
      c = repository.load('InterWikiName')
      r = /\s*\*\s*\[(\S+)\s+(\S+)\]\s*(\S+)?/
      c.each {|l|
	if m = r.match(l)
	  @url[m[2]] = m[1]
	  @code[m[2]] = m[3]
	end
      }
    end
    def url(name)
      return @url[name]
    end
    def code(name)
      return @code[name]
    end
  end
end

