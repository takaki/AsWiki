#! /usr/bin/env ruby

require 'cgi'
require 'obaq/htmlgen'

require 'wwiki/repository'
require 'wwiki/parser'
require 'wwiki/page'
require 'wwiki/exception'

require 'digest/md5'

if $0 == __FILE__ or defined?(MOD_RUBY)
  load ('wwiki.conf')
  $repository = WWiki::Repository.new('.')
  Dir.glob('plugin/*.rb').each{|p| require p}
  include Obaq::HtmlGen
  cgi = CGI.new
  c = cgi['c'][0]
  c =  c.to_s == '' ? 'v' : c
  name = cgi['p'][0]
  name = name.to_s == '' ? $TOPPAGENAME : name
  $pname = name
  begin
    case c
    when 'v'
      if name =~ /[^:]+:[^:]+/
	raise 'interwikiname'
      elsif $repository.exist?(name)
	c = $repository.load(name)
	p = WWiki::Parser.new(CGI::escapeHTML(c.to_s))
	data = {:title => WWiki::unescape(name), :content => p.tree.to_s,
	  :edit => E(:a, A(:href , "#{$CGIURL}?c=e&p=#{name}")){'Edit'},
	  :recentpages => E(:a, A(:href, "#{$CGIURL}?c=h")){'RecentPages'},
	  :allpages => E(:a, A(:href, "#{$CGIURL}?c=a")){'AllPages'},
	  :lastmodified => $repository.mtime(name),
	  :wikilinks => p.wikilinks }
	page = WWiki::Page.new('View', data)
      else
	page = WWiki::editpage(name, '')
      end
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 'e'
      c = $repository.load(name)
      page = WWiki::editpage(name, c)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 'a'
      p = WWiki::Parser.new('#allpages')
      data = {:title => 'AllPages', :content => p.tree.to_s, }
      page  = WWiki::Page.new('Ro',data)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 'h'
      p = WWiki::Parser.new('#recentpages')
      data = {:title => 'RecentPages', :content => p.tree.to_s, }
      page  = WWiki::Page.new('Ro',data)
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 's'
      content = cgi['content'][0] # XXX
      begin
	if cgi['md5sum'][0] != 
	    Digest::MD5::new($repository.load(name).to_s).to_s
	  raise WWiki::TimestampMismatchError
	end
      rescue Errno::ENOENT
      end
      $repository.save(name, content)
      cgi.out({'Status' => '302 REDIRECT', 'Location' => "#{$CGIURL}?c=v&p=#{name}"}){''}
    when 'post'
      session = CGI::Session.new(cgi ,{'tmpdir' => 'attr'})
      if cgi['md5sum'][0] != 
	  Digest::MD5::new($repository.load(session['pname']).to_s).to_s
	raise WWiki::TimestampMismatchError
      end
      cgi.params.each{|key, value| session[key] = value}
      plugin = eval(session['plugin'] + '.new')
      plugin.onpost(session)
      cgi.out({'Status' => '302 REDIRECT', 'Location' => 
		"#{$CGIURL}?c=v&p=#{session['pname']}"}){''}
    else
      raise "Unknown Command '#{c}'"
    end
  rescue WWiki::RuntimeError
    data = {:title => $!.type, :content => $!.message + "\n",
      :edit => E(:a, A(:href , "#{$CGIURL}?c=e&p=#{name}")){'Edit'}}
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      WWiki::Page.new('Error', data).to_s
    }

  rescue Exception
    data = {:title => $!.type, :content => $!.to_s + "\n" + 
      $!.backtrace.join("\n"),
      :edit => E(:a, A(:href , "#{$CGIURL}?c=e&p=#{name}")){'Edit'}}
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      WWiki::Page.new('Error', data).to_s
    }
  end    
end
