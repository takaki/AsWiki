# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'wwiki/plugin'
require 'obaq/htmlgen'
require 'cgi/session'
require 'wwiki/util'

module WWiki
  class W2chBBSPlugin < Plugin
    Name = '2chbbs'
    include Obaq::HtmlGen
    include WWiki::Util
    def onpost(session)
      pname = session['pname']
      number = session['number'].to_i + 1
      poster = (session['poster'] =! '' ? session['poster'] : "名無しさん")
      name = (session['mail'] =! '' ? 
		"[mailto:#{session['mail']} #{poster}]" :
		"[[#{poster}]]")
      t = Time.now
      time = sprintf('%d/%d/%d (%s) %02d:%02d', t.year, t.mon, t.day, 
		     weekstr(t.wday), t.hour, t.min)
      data = "\n#{number}: 名前: #{name} 投稿日: #{time} .\n" +
	session['textdata'] + "\n"
      file = @repository.load(pname)
      file[session['begin'].to_i-1, 0 ] = data
      file[session['begin'].to_i] = "#2chbbs #{number}\n"
      @repository.save(pname, file.to_s)
    end
    def onview(line, b, e, av=[])
      session = CGI::Session.new(CGI::new, {'tmpdir' => 'session'})
      session['pname'] = $pname
      session['plugin'] = self.type
      session['begin'] = b
      session['end'] = e
      session['number'] = av[1].to_i
      data = {:hidden => [e(:input, {:type => 'hidden', 
			      :name => '_session_id', 
			      :value => session.session_id}),
	  e(:input, {:type => 'hidden', :name => 'c', :value => 'post'}),
	  e(:input, {:type => 'hidden', :name => 'md5sum', :value => 
	      Digest::MD5::new(@repository.load($pname).to_s)})

	]}
      form = load_template.expand(data)
      @view = form.to_s
    end
    private
    def weekstr(i)
      return %w[日 月 火 水 木 金 土][i] 
    end
  end
end

