# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

module AsWiki
  class TimestampMismatchError < RuntimeError
  end
  class EditPage < RuntimeError
    def initialize(pname, body=nil, message=nil)
      @pname = pname
      @body  = body
      @message = message
    end
    attr_reader :pname, :body, :message
  end
end
