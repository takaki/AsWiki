#! /usr/bin/ruby 
# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

$TOPPAGENAME = 'IndexPage'
$TIMEFORMAT  ="%F/%T %z"
$BASEDIR     = '.'
$USEATTACH   = true
$LANG        = 'ja'
# $SAFE = 1

load ('aswiki.conf')

$metapages = {
  'MetaPages'   => '#metapages',
  'RecentPages' => '#recentpages',
  'AllPages'    => '#allpages',
  'OrphanedPages' => '#orphanedpages',
  'NotCreatedPages' => '#notcreatedpages',
  'PluginList' => '#pluginlist',
}

require 'cgi'

require 'aswiki/repository'
require 'aswiki/parser'
require 'aswiki/page'
require 'aswiki/exception'
require 'aswiki/interwiki'
require 'aswiki/backup'
require 'aswiki/pagedata'
require 'aswiki/cgi'

if $USEATTACH
  require 'aswiki/attachdb'
end

require 'digest/md5'
require 'amrita/template'
require 'amrita/format'



if $0 == __FILE__ or defined?(MOD_RUBY)
  include AsWiki::Util
  Dir::chdir $BASEDIR
  Amrita::TemplateFileWithCache::set_cache_dir('cache')
  AsWiki::Node::load_parts_template unless defined? $aswiki_parts_template_loaded
  $aswiki_parts_template_loaded = true
  repository = AsWiki::Repository.new('.')
  Dir.glob('plugin/*.rb').select {|p| 
    $USEATTACH or p != 'plugin/attach.rb' # XXX
  }.each{|p| 
    require p.untaint  
  }

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
	  if $metapages.key?(name)
	    pd.parsetext($metapages[name])
	    page  = AsWiki::Page.new('Ro', pd)
	  elsif repository.exist?(name)
	    pd.parsefile
	    page = AsWiki::Page.new('View', pd)
	  else
	    raise AsWiki::EditPageCall.new(name)
	  end
	  cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	    # $xxxx = 0 unless defined? $xxxx
	    # $xxxx += 1
	    # page.to_s + $xxxx.to_s + ':' + $$.to_s
	    page.to_s
	  }
	end
      when 'e'
	raise AsWiki::EditPageCall.new(name)
      when 'r'
	c = repository.load(name)
	data = {
	  :title => name ,
	  :body => Amrita::pre { Amrita::e(:code) {  c.to_s  } } # XXX parts template ??
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
  rescue AsWiki::AsWikiError
    data = {:title => $!.type.to_s , 
      :body => Amrita::pre { Amrita::e(:code) {
	  $!.message + "\n"}
      }
    }
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      # $! + $@.join +
      AsWiki::Page.new('Error', data).to_s
    }
  rescue Exception
    data = {:title => 'Script Error: ' + $!.type.to_s,
      :body => Amrita::pre { Amrita::e(:code) {
	  $!.to_s + "\n" +  $!.backtrace.join("\n") # XXX pre
	} 
      } # XXX parts template ??
    } 
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', data).to_s
    }
  end    
end


