# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'dbm'

module AsWiki
  class RevLink
    def initialize
      @db = DBM::new('cache/revlink')
    end
    def clear
      @db.clear
    end
    def regist(page, links)
      links.each{|l|
	ll = @db.has_key?(l) ? @db[l].split : []
	ll = ll | [page]
	@db[l] = ll.join(' ')
      }
    end
    def list(page)
      r = @db[page]
      return r ? r.split : []
    end
  end
end
