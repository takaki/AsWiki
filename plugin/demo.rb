# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'aswiki/plugin'
require 'cgi/session'

module AsWiki
  class NowPlugin < Plugin
    Name = 'now'
    def onview(line, b, e, av=[])
      @view = Time.now.to_s
    end
  end
end

module AsWiki
  class PrintblockPlugin < Plugin
    Name = 'printblock'
    def onview(line, b, e, av=[])
      @view = line.map{|l| b=b+1 ; ["#{b-1}: #{l}", Amrita::e(:br),"\n"] }
    end
  end
end
module AsWiki
  class ListPlugin < Plugin
    Name = 'list'
    def onpost(session)
      pname = session['pname']
      file = @repository.load(pname)
      file[session['begin'].to_i-1, 0 ] = " * #{CGI.new['item']}\n"
      @repository.save(pname, file.to_s)
    end
    def onview(line, b, e, av=[])
      session = CGI::Session.new(CGI::new, {'new_session'=>true,
				   'tmpdir' => 'session'})
      session['pname'] = @name
      session['plugin'] = self.type
      session['begin'] = b
      session['end'] = e
      # session.close
      data = {:session_id => session.session_id,
	:md5sum =>  Digest::MD5::new(@repository.load(@name).to_s).to_s}
      load_template.expand(@view, data)
      @view = Amrita::noescape{@view}
    end
  end
end

