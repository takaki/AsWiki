# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'cgi'

class CGI
  def multipart?
    if ENV['CONTENT_TYPE'].nil? or
	ENV['CONTENT_TYPE'].index(%r|\Amultipart/form-data|).nil?
      return false
    else
      return true
    end
  end
  private :multipart?
  def value(key)
    val = @params[key]
    ret = val.collect{|v|
      multipart?() ? v.read : v
    }
    # ret.size == 1 ? ret[0] : ret
  end
  def original_filename(key)
    ret = @params[key].collect{|f|
      f.original_filename
    }
    # ret.size == 1 ? ret[0] : ret
  end
  def content_type(key)
    ret = @params[key].collect{|f|
      f.content_type
    }
    # ret.size == 1 ? ret[0] : ret
  end
end
