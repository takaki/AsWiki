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
    if $USEBACKUP
      HandlerTable['h'] = self      
    end
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

  class HistoryRawHandler < Handler
    if $USEBACKUP
      HandlerTable['hr'] = self      
    end
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
      pd.body = Amrita::pre { Amrita::e(:code) {  c.to_s  } } # XXX
      page = AsWiki::Page.new('History', pd)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    end
  end

  class DiffHandler < Handler
    if $USEBACKUP
      HandlerTable['d'] = self      
    end
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
      if body[-1,1] != "\n"; body << "\n" ;end
      begin
	c = @repository.load(name)
	if cgi.value('md5sum')[0] !=  Digest::MD5::new(c.to_s).to_s
	  bl = body.map{|l| l.sub("\r\n", "\n")}
	  raise AsWiki::SaveConflict.new(name, AsWiki::merge(c, bl, false))
	end

	bol = (cgi.value('ebol')[0] or 1).to_i
	eol = (cgi.value('eeol')[0] or c.size).to_i
	c[bol-1...eol] = body.to_s
	body = c.to_s
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
    if $USEATTACH
      HandlerTable['attach'] = self      
    end
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
    if $USEATTACH
      HandlerTable['download'] = self      
    end
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
    if $USEATTACH
      HandlerTable['delete'] = self      
    end
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
	c = [true]
      end
      pd = AsWiki::PageData.new(pname)
      pd.md5sum = Digest::MD5::new(c.to_s).to_s
      pd.title  = title
      if body.nil?
	bol = (cgi.value('ebol')[0] or 1).to_i
	eol = (cgi.value('eeol')[0] or c.size).to_i
	pd.body   = c[bol-1...eol]
	pd.ebol   = bol
	pd.eeol   = eol
      else
	pd.body   = body
	pd.ebol   = 1
	pd.eeol   = c.to_a.size # XXX ???
      end
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

  class RSSHandler < Handler
    if $USERSS
      HandlerTable['rss'] = self      
    end
    def initialize(cgi, name)
      super
      c = @repository.load(name)
      tmplfile = File.join('template','RSS.xml')
      template = Amrita::TemplateFileWithCache[tmplfile]
      template.expand_attr = true
      template.use_compiler = true
      template.xml = true
      template.asxml = true


      count = 15
      data = {
	:title => $TITLE,
	:language => $LANG,
	:link => $CGIURL,
	:description => "#{$TITLE}: RecentPages",
	:data => @repository.attrlist.sort{|a,b| b[1] <=> a[1]}[0,count].map{|l| 
	  {
	    :title => l[0],
	    :link  => cgiurl([['c','v'],['p',l[0]]]),
	    :description => timestr(l[1]),
	  }
	}
      }
      
      @str = ''
      template.expand(@str, data)

      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/rss'}){
	@str
      }
    end
  end
end
