#! /usr/bin/env ruby

require 'cgi'
require 'obaq/htmlgen'

require 'wwiki/repository'
require 'wwiki/parser'
require 'wwiki/page'


if $0 == __FILE__ or defined?(MOD_RUBY)
  load ('wwiki.conf')
  include Obaq::HtmlGen
  cgi = CGI.new
  c = cgi['c'][0]
  c =  c.to_s == '' ? 'v' : c
  begin
    case c
    when 'v'
      repository = WWiki::Repository.new('.')
      name = cgi['p'][0]
      name = name.to_s == '' ? $TOPPAGENAME : name
      c = repository.read(name)
      p = WWiki::Parser.new(CGI::escapeHTML(c.to_s))
      data = {:title => name, :content => p.tree.to_s,
	:edit => E(:a, A(:href , "#{$CGIURL}?c=e&p=#{name}")){'Edit'}}
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	WWiki::Page.new('View', data).to_s
      }
    when 'e'
      repository = WWiki::Repository.new('.')
      name = cgi['p'][0]
      name = name == '' ? $TOPPAGENAME : name
      c = repository.read(name)
      data = {:title => name, :content => CGI::escapeHTML(c.to_s),
	:edit => E(:a, A(:href , "#{$CGIURL}?c=e&p=#{name}")){'Edit'}}
      page = WWiki::Page.new('Edit', data)
      page.tree.each do |e|
	case e[:action]
	when 'save'
	  e[:action] = "#{$CGIURL}"
	end
	if e[:name] == 'p'
	  e[:value] = name
	end
      end
      cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
	page.to_s
      }
    when 's'
      repository = WWiki::Repository.new('.')
      name = cgi['p'][0] # XXX
      name = name == '' ? $TOPPAGENAME : name # XXX
      content = cgi['content'][0] # XXX
      repository.save(name, content)
      cgi.out({'Status' => '302 REDIRECT', 'Content-Type' => 'text/html',
		'Location' => "#{$CGIURL}?c=v&p=#{name}"}){''}
    else
      raise 
    end
  rescue Exception
    data = {:title => $!.type, :content => $!.to_s + "\n" + 
      $!.backtrace.join("\n"),
      :edit => E(:a, A(:href , "#{$CGIURL}?c=e&p=#{name}")){'Edit'}}
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      WWiki::Page.new('Error', data).to_s
    }
  end    
end

