#! /usr/bin/ruby 
# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

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

require 'digest/md5'
require 'amrita/template'

# default value. if you think change them, use 'aswiki.conf'.
$TOPPAGENAME = 'IndexPage'
$TIMEFORMAT  ="%F %T %z"
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
  load ('aswiki.conf')
  repository = AsWiki::Repository.new('.')
  Dir.glob('plugin/*.rb').each{|p| require p.untaint} # XXX
  cgi = FCGI.new
  c, = cgi.value('c')
  c  = c.nil? ? 'v' : c
  name, = cgi.value('p')
  name  = name.nil? ? $TOPPAGENAME : name
  begin
    case c
    when 'v'
      if name =~ /[^:]+:[^:]+/
	iname, iwiki = name.split(':') 
	iwdb = AsWiki::InterWikiDB.new
	url = iwdb.url(iname)
	cgi.out({'Status' => '302 REDIRECT',
		  'Location' => "#{url}#{iwiki}"}){''}
      else
	if MetaPages.key?(name)
	  p = AsWiki::Parser.new(MetaPages[name])
	  data = {:title => name, :body => p.tree }
	  page  = AsWiki::Page.new('Ro',data)
	elsif repository.exist?(name)
	  pd = AsWiki::PageData.new(name)
	  page = AsWiki::Page.new('View', pd)
	else
	  page = AsWiki::editpage(name, '')
	end
	cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	  page.to_s 
	}
      end
    when 'e'
      c = repository.load(name)
      page = AsWiki::editpage(name, c)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 'r'
      c = repository.load(name)
      data = {
	:title => 'Raw data of ' + name ,
	:body => c.to_s
      }
      page = AsWiki::Page.new('Raw', data)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 'd'
      backup = AsWiki::Backup.new('.')
      cn  = repository.load(name)
      log = backup.rlog(name)
      if log.length > 1
	co = backup.co(name, log[1][0])
      else
	co = ''
      end
      data = {
	:title => 'Diff of ' + name ,
	:body => AsWiki::diff(co,cn) # .to_s
      }
      page = AsWiki::Page.new('Ro', data)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 's'
      body = cgi['body'][0]
      begin
	if cgi['md5sum'][0] != 
	    Digest::MD5::new(repository.load(name).to_s).to_s
	  raise AsWiki::TimestampMismatchError
	end
      rescue Errno::ENOENT
      end
      repository.save(name, body)
      cgi.out({'Status' => '302 REDIRECT', 
		'Location' => "#{$CGIURL}?c=v;p=#{AsWiki::escape(name)}"}){''}
    when 'post'
      session = CGI::Session.new(cgi ,{'tmpdir' => 'session'}) # XXX
      if cgi['md5sum'][0] != 
	  Digest::MD5::new(repository.load(session['pname']).to_s).to_s
	raise AsWiki::TimestampMismatchError
      end
      cgi.params.each{|key, value| session[key] = value}
      plugin = eval(session['plugin'] + '.new(name)')
      plugin.onpost(session)
      cgi.out({'Status' => '302 REDIRECT', 'Location' => 
		"#{$CGIURL}?c=v;p=#{session['pname']}"}){''}
    when 'attach'
      cgi['_session_id'][0] = cgi.value('_session_id')[0] # XXXX cgi.rb bug
      session = CGI::Session.new(cgi ,{'tmpdir' => 'session'}) # XXX
      plugin = eval(session['plugin'] + '.new(name)')
      plugin.onpost(session, cgi['file'])
      cgi.out({'Status' => '302 REDIRECT', 'Location' => 
		"#{$CGIURL}?c=v;p=#{session['pname']}"}){''}
    when 'download'
      mime = BDB::Btree.open("attach/mime.db", nil, BDB::CREATE)
      namedb = BDB::Btree.open("attach/name.db", nil, BDB::CREATE)
      page = BDB::Btree.open("attach/page.db", nil, BDB::CREATE)
      num  = cgi['num'][0]
      
      type = mime[num]
      pathname = "attach/#{num}"
      cgi.out({'type' => type,
		'Last-Modified' => 
		CGI::rfc1123_date(File::stat(pathname).mtime),
		"Content-Disposition" => 
		%Q|attachment; filename="#{name[num]}"|}
	      ){ open(pathname).read }
    when 'delete' # XXX plugin onpost?
      mime = BDB::Btree.open("attach/mime.db", nil, BDB::CREATE)
      namedb = BDB::Btree.open("attach/name.db", nil, BDB::CREATE)
      page = BDB::Btree.open("attach/page.db", nil, BDB::CREATE)
      num  = cgi['num'][0]
      pathname = File.join('attach', num)
      File::unlink(pathname)
      mime.delete(num)
      namedb.delete(num)
      page.delete(num)
      cgi.out({'Status' => '302 REDIRECT', 
		'Location' => "#{$CGIURL}?c=v;p=#{name}"}){''}
    else
      raise ArgumentError, "Unknown Command '#{c}'\n"
    end
  rescue AsWiki::RuntimeError
    data = {:title => $!.type, :body => $!.message + "\n",
    }
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', data).to_s
    }

  rescue Exception
    data = {:title => $!.type.to_s + "(#{$!.message})", 
      :body => $!.to_s + "\n" +  $!.backtrace.join("\n"),
   } 
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', data).to_s
    }
  end    
end
