#! /usr/bin/env ruby

require 'cgi'
require 'wwiki/repository'
require 'wwiki/parser'
require 'wwiki/page'

if $0 == __FILE__ or defined?(MOD_RUBY)
  cgi = CGI.new
  c = cgi['c'][0]
  case c
  when 'v'
    repository = WWiki::Repository.new('text')
    name = cgi['p'][0]
    c = repository.read(name)
    p = WWiki::Parser.new(c.to_s)
    data = {:title => name, :content => p.tree.to_s}
    print "Status: 200 OK\r\n"
    print "Content-Type: text/html\r\n"
    print "\r\n"
    print WWiki::Page.new('ViewPage', data)
  else
    p c
    raise 
  end
end

