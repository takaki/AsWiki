# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/plugin'
require 'cgi/session'

module AsWiki
  class NowPlugin < Plugin
    Name = 'now'
    def onview(line, b, e, av=[])
      return Time.now.strftime($TIMEFORMAT)
    end
  end
end

module AsWiki
  class LineNoPlugin < Plugin
    Name = 'lineno'
    def onview(line, b, e, av=[])
      return "lineno #{b}\n"
    end
  end
  class PrintblockPlugin < Plugin
    Name = 'printblock'
    def onview(line, b, e, av=[])
      return line.map{|l| b=b+1 ; ["#{b-1}: #{l}", Amrita::e(:br),"\n"] }
    end
  end
end

module AsWiki
  class ListPlugin < Plugin
    Name = 'list'
    include I18N
    def onpost(session)
      pname = session['pname']
      file = @repository.load(pname)
      file[session['begin'].to_i-1, 0 ] = "* #{CGI.new['item']}\n"
      @repository.save(pname, file.to_s)
    end
    def onview(line, b, e, av=[])
      session = CGI::Session.new(CGI::new, {'new_session'=>true,
				   'tmpdir' => $DIR_SESSION})
      session['pname'] = @name
      session['plugin'] = self.class
      session['begin'] = b
      session['end'] = e
      # session.close
      @data = {
	:session_id => session.session_id,
	:md5sum =>  Digest::MD5::new(@repository.load(@name).to_s).to_s,
	:msg_list_item => msg_list_item,
	:msg_list_add => msg_list_add,
      }
      # @view = load_template.expand_tree(data)
      load_parts
      return self
    end
  end
end

