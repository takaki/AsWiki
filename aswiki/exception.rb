# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

module AsWiki
  class AsWikiError < RuntimeError
  end
  class TimestampMismatch < AsWikiError
  end
  class EditPageCall < AsWikiError
    def initialize(pname)
      @pname = pname
    end
    attr_reader :pname
  end
  class SaveConflict < EditPageCall
    def initialize(pname, body)
      @pname = pname
      @body  = body
    end
    attr_reader :pname, :body
  end
end

