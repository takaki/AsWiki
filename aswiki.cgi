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

require 'digest/md5'
require 'amrita/template'

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
  class << cgi
    def multipartcheck
      @multipart = false
      if %r|^multipart/form-data| =~ ENV['CONTENT_TYPE'] 
	@multipart = true
      end
    end
    def sval(key)
      if @multipart
	return self[key][0] ? self[key][0].gets : ''
      else
	return self[key][0] 
      end
    end
  end
  cgi.multipartcheck
  c = cgi.sval('c')
  c =  c.to_s == '' ? 'v' : CGI::escapeHTML(c)
  name = cgi.sval('p')
  # name = name.to_s == '' ? $TOPPAGENAME : CGI::escapeHTML(name)
  name = name.to_s == '' ? $TOPPAGENAME : name
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
	  data = {:title => name, :contents => p.tree.to_s, }
	  page  = AsWiki::Page.new('Ro',data)
	elsif repository.exist?(name)
	  pd = AsWiki::PageData.new(name)
	  data = {:title => name, 
	    :contents => Amrita::noescape{pd.tree.to_s},
	    :edit => "#{$CGIURL}?c=e;p=#{AsWiki::escape(name)}",
	    :toppage => "#{$CGIURL}?c=v;p=#{$TOPPAGENAME}",
	    :recentpages => "#{$CGIURL}?c=v;p=RecentPages",
	    :allpages => "#{$CGIURL}?c=v;p=AllPages",
	    :rawpage => "#{$CGIURL}?c=r;p=#{AsWiki::escape(name)}",
	    :diffpage => "#{$CGIURL}?c=d;p=#{AsWiki::escape(name)}",
	    :helppage => "#{$CGIURL}?c=v;p=HelpPage",
	    :lastmodified => repository.mtime(name),
	    :wikilinks => pd.wikilinks,
	  }
	  page = AsWiki::Page.new('View', data)
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
	:contents => c.to_s
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
	:contents => AsWiki::diff(co,cn) # .to_s
      }
      page = AsWiki::Page.new('Ro', data)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 's'
      content = cgi['content'][0]
      begin
	if cgi['md5sum'][0] != 
	    Digest::MD5::new(repository.load(name).to_s).to_s
	  raise AsWiki::TimestampMismatchError
	end
      rescue Errno::ENOENT
      end
      repository.save(name, content)
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
      exit
    when 'attach'
      cgi['_session_id'][0] = cgi.sval('_session_id') # xXXX
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
      raise "Unknown Command '#{c}'<br>"
    end
  rescue AsWiki::RuntimeError
    data = {:title => $!.type, :contents => $!.message + "\n",
    }
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', data).to_s
    }

  rescue Exception
    data = {:title => $!.type, :contents => $!.to_s + "\n" + 
      $!.backtrace.join("\n"),
   } 
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', data).to_s
    }
  end    
end
