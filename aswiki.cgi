#! /usr/bin/ruby 
# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

# $SAFE = 1
require 'cgi'

require 'aswiki/repository'
require 'aswiki/parser'
require 'aswiki/page'
require 'aswiki/exception'
require 'aswiki/interwiki'
require 'aswiki/backup'
require 'aswiki/pagedata'
require 'aswiki/cgi'
require 'aswiki/attachdb'

require 'digest/md5'
require 'amrita/template'

# default value. if you think change them, use 'aswiki.conf'.
$TOPPAGENAME = 'IndexPage'
$TIMEFORMAT  ="%F/%T %z"
$BASEDIR     = '.'
# $SAFE = 1

MetaPages = {
  'MetaPages'   => '#metapages',
  'RecentPages' => '#recentpages',
  'AllPages'    => '#allpages',
  'OrphanedPages' => '#orphanedpages',
  'NotCreatedPages' => '#notcreatedpages',
  'PluginList' => '#pluginlist',
}

if $0 == __FILE__ or defined?(MOD_RUBY)
  include AsWiki::Util
  load ('aswiki.conf')
  repository = AsWiki::Repository.new('.')
  Dir.glob('plugin/*.rb').each{|p| require p.untaint} # XXX
  cgi = FCGI.new
  c = cgi.value('c')[0]
  c = c.nil? ? 'v' : c
  name = cgi.value('p')[0]
  name = name.nil? ? $TOPPAGENAME : name
  begin
    begin
      case c
      when 'v'
	if name =~ /[^:]+:[^:]+/
	  iname, iwiki = name.split(':') 
	  iwdb = AsWiki::InterWikiDB.new
	  url = iwdb.url(iname)
	  AsWiki::redirectpage(cgi,  "#{url}#{iwiki}")
	else
	  pd = AsWiki::PageData.new(name)
	  if MetaPages.key?(name)
	    pd.parsetext(MetaPages[name])
	    page  = AsWiki::Page.new('Ro', pd)
	  elsif repository.exist?(name)
	    pd.parsefile
	    page = AsWiki::Page.new('View', pd)
	  else
	    raise AsWiki::EditPageCall.new(name)
	  end
	  cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	    page.to_s 
	  }
	end
      when 'e'
	raise AsWiki::EditPageCall.new(name)
      when 'r'
	c = repository.load(name)
	data = {
	  :title => name ,
	  :body => c.to_s
	}
	page = AsWiki::Page.new('Raw', data)
	cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	  page.to_s
	}
      when 'h'
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
      when 'd'
	revnew = cgi.value('rn')[0].to_i
	revold = cgi.value('ro')[0].to_i

	backup = AsWiki::Backup.new('.')
	log = backup.rlog(name)

	cn = revnew == 0 ? repository.load(name) : backup.co(name, revnew)
	co = revold == 0 ? backup.co(name, log[1][0]) : backup.co(name, revold)
	data = {
	  :title => 'Diff of ' + name + "(new #{revnew}, old #{revold})",
	  :body => AsWiki::merge(co,cn)
	}
	page = AsWiki::Page.new('Ro', data)
	cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	  page.to_s
	}
      when 's'
	body = cgi.value('body')[0]
	begin
	  c = repository.load(name).to_s
	  if cgi.value('md5sum')[0] !=  Digest::MD5::new(c).to_s
	    bl = body.map{|l| l.sub("\r\n", "\n")}
	    cl = c.map{|l| l}
	    raise AsWiki::EditPageCall.new(name, AsWiki::merge(cl, bl, false),true)
	  end
	rescue Errno::ENOENT
	end
	repository.save(name, body)
	AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',name]]))
      when 'post'
	session = CGI::Session.new(cgi ,{'tmpdir' => 'session'}) # XXX
	if cgi['md5sum'][0] != 
	    Digest::MD5::new(repository.load(session['pname']).to_s).to_s
	  raise AsWiki::TimestampMismatch
	end
	cgi.params.each{|key, value| session[key] = value}
	plugin = AsWiki::Plugin::PluginTableByType[session['plugin']].new(name)
	plugin.onpost(session)
	AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',session['pname']]]))
      when 'attach'
	cgi['_session_id'][0] = cgi.value('_session_id')[0] # XXXX cgi/session bug
	session = CGI::Session.new(cgi ,{'tmpdir' => 'session'}) # XXX
	plugin = AsWiki::Plugin::PluginTableByType[session['plugin']].new(name)
	plugin.onpost(session, cgi['file'])
	AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',session['pname']]]))
      when 'download'
	num  = cgi.value('num')[0]
	adb = AsWiki::AttachDB.new
	file = adb.loadfile(num)
	cgi.out({'type' => file[:type],
		  'Last-Modified' =>  CGI::rfc1123_date(file[:mtime]),
		  "Content-Disposition" => 
		  %Q|attachment; filename="#{file[:filename]}"|}
		){file[:body] }
      when 'delete' # XXX plugin onpost?
	num  = cgi.value('num')[0]
	adb = AsWiki::AttachDB.new
	adb.deletefile(num)
	AsWiki::redirectpage(cgi, cgiurl([['c','v'],['p',name]]))
      else
	raise AsWiki::RuntimeError, "Unknown Command '#{c}'\n"
      end
    rescue AsWiki::EditPageCall
      pname   = $!.pname
      body    = $!.body
      message = $!.message
      begin
	c = repository.load(pname) 
      rescue Errno::ENOENT
	c = ''
      end
      if body.nil?
	body = c
      end
      data = {:title => (message ? '(Edit Confilct)' : '') + pname ,
	:body => body,
	:name => name,
	:md5sum => Digest::MD5::new(c.to_s).to_s, # confl
      }
      page = AsWiki::Page.new('Edit', data)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    end
  rescue AsWiki::RuntimeError
    data = {:title => $!.type.to_s , :body => $!.message + "\n"}
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', data).to_s
    }
  rescue Exception
    data = {:title => $!.type.to_s,
      :body => $!.to_s + "\n" +  $!.backtrace.join("\n"),
   } 
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', data).to_s
    }
  end    
end
