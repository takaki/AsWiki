require 'wwiki/repository'

module WWiki
  class InterWikiDB
    def initialize
      @url = {}
      @code = {}
      repository = WWiki::Repository.new
      c = repository.load('InterWikiName')
      r = /\s+\*\s*\[(\S+)\s+(\S+)\]\s*(\S+)?/
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

