# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

class AsWikiRuntimeError < RuntimeError
end
class TimestampMismatch < AsWikiRuntimeError
end
class EditPageCall < AsWikiRuntimeError
  def initialize(pname, body=nil, message=nil)
    @pname = pname
    @body  = body
    @message = message
  end
  attr_reader :pname, :body, :message
end
