require 'wwiki/plugin'
require 'cgi/session'

module WWiki
  class NowPlugin < Plugin
    Name = 'now'
    def onview(line, b, e, av=[])
      @view = Time.now.to_s
    end
  end
end

module WWiki
  class PrintblockPlugin < Plugin
    Name = 'printblock'
    def onview(line, b, e, av=[])
      @view = line.map{|l| b=b+1 ;"#{b-1}: #{l}<br>\n" }.to_s 
    end
  end
end
module WWiki
  class ListPlugin < Plugin
    Name = 'list'
    def onpost(session)
      pname = session['pname']
      file = @repository.load(pname)
      file[session['begin'].to_i-1, 0 ] = " * #{CGI.new['item']}\n"
      @repository.save(pname, file.to_s)
    end
    def onview(line, b, e, av=[])
      session = CGI::Session.new(CGI::new, {'tmpdir' => 'attr'})
      session['pname'] = $pname
      session['plugin'] = self.type
      session['begin'] = b
      session['end'] = e
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
  end
end

