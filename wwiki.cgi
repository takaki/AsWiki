#! /usr/bin/env ruby

require 'cgi'
require 'wwiki/repository'
require 'wwiki/parser'

if $0 == __FILE__ or defined?(MOD_RUBY)
  cgi = CGI.new
  c = cgi['c'][0]
  case c
  when 'v'
    rep = WWiki::Repository.new('text')
    c = rep.read(cgi['p'][0])
    p = WWiki::Parser.new(c.to_s)
    print p.tree.to_s
  else
    p c
    raise 
  end
end

