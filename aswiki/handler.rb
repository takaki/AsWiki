# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'aswiki/exception'
require 'aswiki/interwiki'

module AsWiki
  HandlerTable = {}
  class Handler
    def initialize(cgi, name)
      @repository = AsWiki::Repository.new('.')
    end
  end
  class ViewHandler < Handler
    HandlerTable['v'] = self
    def initialize(cgi, name)
      super
      if name =~ /[^:]+:[^:]+/
	iname, iwiki = name.split(':') 
	iwdb = AsWiki::InterWikiDB.new
	url = iwdb.url(iname)
	AsWiki::redirectpage(cgi,  "#{url}#{iwiki}")
      else
	pd = AsWiki::PageData.new(name)
	if $metapages.key?(name)
	  pd.parsetext($metapages[name])
	  page  = AsWiki::Page.new('Ro', pd)
	elsif @repository.exist?(name)
	  pd.parsefile
	  page = AsWiki::Page.new('View', pd)
	else
	  raise AsWiki::EditPageCall.new(name)
	end
	cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	  page.to_s
	}
      end
    end
  end
  class EditHandler < Handler
    HandlerTable['e'] = self      
    def initialize(cgi, name)
      super
      raise AsWiki::EditPageCall.new(name)
    end
  end
  class RawHandler < Handler
    HandlerTable['r'] = self      
    def initialize(cgi, name)
      super
      c = @repository.load(name)
      pd = AsWiki::PageData.new(name)
      pd.body = Amrita::pre { Amrita::e(:code) {  c.to_s  } } # XXX
      page = AsWiki::Page.new('Raw', pd)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    end
  end

  class HistoryHandler < Handler
    HandlerTable['h'] = self      
    def initialize(cgi, name)
      super
      rev = cgi.value('rev')[0].to_i
      backup = AsWiki::Backup.new('.')
      if rev == 0
	rev = backup.rlog(name)[0][0]
      end
      c = backup.co(name, rev)
      pd = AsWiki::PageData.new(name)
      pd.revision  = rev
      pd.timestamp = backup.rlog(name, rev)[0][1]
      pd.parsetext(c.to_s)
      page = AsWiki::Page.new('History', pd)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    end
  end

  class DiffHandler < Handler
    HandlerTable['d'] = self      
    def initialize(cgi, name)
      super
      revnew = cgi.value('rn')[0].to_i
      revold = cgi.value('ro')[0].to_i

      backup = AsWiki::Backup.new('.')
      log = backup.rlog(name)

      cn = revnew == 0 ? @repository.load(name) : backup.co(name, revnew)
      co = revold == 0 ? backup.co(name, log[1][0]) : backup.co(name, revold)

      pd = AsWiki::PageData.new(name)
      pd.title = 'Diff of ' + name + "(new #{revnew}, old #{revold})"
      pd.body  = AsWiki::merge(co,cn)
      page = AsWiki::Page.new('Ro', pd)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    end
  end

  class SaveHandler < Handler
    HandlerTable['s'] = self      
    def initialize(cgi, name)
      super
      body = cgi.value('body')[0]
      begin
	c = @repository.load(name).to_s
	if cgi.value('md5sum')[0] !=  Digest::MD5::new(c).to_s
	  bl = body.map{|l| l.sub("\r\n", "\n")}
	  cl = c.map{|l| l}
	  raise AsWiki::SaveConflict.new(name, AsWiki::merge(cl, bl, false))
	end
      rescue Errno::ENOENT
      end
      @repository.save(name, body)
      AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',name]]))
    end
  end

  class PostHandler < Handler
    HandlerTable['post'] = self      
    def initialize(cgi, name)
      super
      session = CGI::Session.new(cgi ,{'tmpdir' => 'session'}) # XXX
      if cgi['md5sum'][0] != 
	  Digest::MD5::new(@repository.load(session['pname']).to_s).to_s
	raise AsWiki::TimestampMismatch
      end
      cgi.params.each{|key, value| session[key] = value}
      plugin = AsWiki::Plugin::PluginTableByType[session['plugin']].new(name)
      plugin.onpost(session)
      AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',session['pname']]]))
    end
  end

  class AttachHandler < Handler
    HandlerTable['attach'] = self      
    def initialize(cgi, name)
      super
      cgi['_session_id'][0] = cgi.value('_session_id')[0] # XXXX cgi/session bug
      session = CGI::Session.new(cgi ,{'tmpdir' => 'session'}) # XXX
      plugin = AsWiki::Plugin::PluginTableByType[session['plugin']].new(name)
      plugin.onpost(session, cgi['file'])
      AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',session['pname']]]))
    end
  end

  class DownloadHandler < Handler
    HandlerTable['download'] = self      
    def initialize(cgi, name)
      super
      num  = cgi.value('num')[0]
      adb = AsWiki::AttachDB.new
      file = adb.loadfile(num)
      cgi.out({'type' => file[:type],
		'Last-Modified' =>  CGI::rfc1123_date(file[:mtime]),
		"Content-Disposition" => 
		%Q|attachment; filename="#{file[:filename]}"|}
	      ){file[:body] }
    end
  end

  class DeleteHandler < Handler # XXX plugin onpost?
    HandlerTable['delete'] = self      
    def initialize(cgi, name)
      super
      num  = cgi.value('num')[0]
      adb = AsWiki::AttachDB.new
      adb.deletefile(num)
      AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',name]]))
    end
  end

  module EditPage
    def makeeditpage(cgi, pname, title, body)
      begin
	c = @repository.load(pname) 
      rescue Errno::ENOENT
	c = true 
      end
      pd = AsWiki::PageData.new(pname)
      pd.md5sum = Digest::MD5::new(c.to_s).to_s
      pd.title  = title
      pd.body   = body.nil? ? c : body
      page = AsWiki::Page.new('Edit', pd)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    end
  end
  class EditPageCallHandler < Handler
    HandlerTable[AsWiki::EditPageCall] = self      
    include EditPage
    def initialize(cgi, e)
      super(cgi, nil)
      makeeditpage(cgi, e.pname,  e.pname, nil)
    end
  end
  class SaveConflictHandler <Handler
    HandlerTable[AsWiki::SaveConflict] = self      
    include EditPage
    def initialize(cgi, e)
      super(cgi, nil)
      makeeditpage(cgi, e.pname, '(Edit Conflict)' + e.pname,  e.body)
    end
  end
end
