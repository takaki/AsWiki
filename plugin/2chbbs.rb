# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/plugin'
require 'cgi/session'
require 'aswiki/util'


module AsWiki
  class W2chBBSPlugin < Plugin
    Name = '2chbbs'
    include AsWiki::Util
    Anonymous = '名無しさん'
    From = '名前'
    Date = '投稿日'
    Weekstr = %w[日 月 火 水 木 金 土]
    def onpost(session)
      pname = session['pname']
      number = session['number'].to_i + 1
      poster = (session['poster'] != '' ? session['poster'] : Anonymous)
      name = (session['mail'] != '' ? 
		"[mailto:#{session['mail']} #{poster}]" :
		"[[#{poster}]]")
      t = Time.now
      time = t.strftime("%Y/%m/%d (#{weekstr(t.wday)}) %R")
      data = "\n#{number}: #{From}: #{name} #{Date}: #{time} \n\n" +
	session['textdata'] + "\n"
      file = @repository.load(pname)
      file[session['begin'].to_i-1, 0 ] = data
      file[session['begin'].to_i] = "#2chbbs #{number}\n"
      @repository.save(pname, file.to_s)
    end
    def onview(line, b, e, av=[])
      session = CGI::Session.new(CGI::new, {'tmpdir' => 'session',
				   'new_session' => true})
      session['pname'] = @name
      session['plugin'] = self.type
      session['begin'] = b
      session['end'] = e
      session['number'] = av[1].to_i
      data = {
	:_session_id => session.session_id,
	:md5sum =>  Digest::MD5::new(@repository.load(@name).to_s).to_s
      }
      @view = load_template.expand_tree(data)
    end
    private
    def weekstr(i)
      return Weekstr[i] 
    end
  end
end

