# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'strscan'
require 'uri/common'
require 'delegate'

module AsWiki
  class Scanner
    PAT_URI =  /\A#{URI::REGEXP::PATTERN::X_ABS_URI}/xn
    C128 = [128].pack('C')
    C255 = [255].pack('C')
    def initialize(str)
      @q = scan(str)
    end
    def next_token
      return @q.shift
    end
    private
    def scan(f)
      q = [] 
      sc = StringScanner.new(f.to_s)
      bol = true
      while sc.rest? do
	if bol
	  bol = false
	  if    tmp = sc.scan(/\A#begin .*$/)
	    q.push [:PLUGIN_BEGIN, tmp]
	  elsif tmp = sc.scan(/\A#end *$/)
	    q.push [:PLUGIN_END, tmp]
	  elsif tmp = sc.scan(/\A#.+$/)
	    q.push [:PLUGIN, tmp]
	  elsif tmp = sc.scan(/\A +\*/)
	    q.push [:UL, tmp]
	  # elsif tmp = sc.scan(/\A +\d+\./)
	  elsif tmp = sc.scan(/\A +\(\d+\)/)
	    q.push [:OL, tmp]
	  elsif tmp = sc.scan(/\A +\+ */)
	    q.push [:DL, tmp]
	  elsif tmp = sc.scan(/\A={2,6}/)
	    q.push [:HN_BEGIN, tmp]
	  elsif tmp = sc.scan(/\A---- *$/)
	    q.push [:HR, tmp]
	  # elsif tmp = sc.scan(/\A *\|\|/)
	  elsif tmp = sc.scan(/\A *\|/)
	    q.push [:TABLE_BEGIN, tmp]
	  elsif tmp = sc.scan(/\A\{\{\{ *$/)
	    q.push [:PRE_BEGIN, tmp]
	  elsif tmp = sc.scan(/\A\}\}\} *$/)
	    q.push [:PRE_END, tmp]
	  elsif tmp = sc.scan(/\A\.$/)
	    q.push [:ENDPERIOD, tmp]
	  elsif tmp = sc.scan(/\A[ \t\r\f]*$/) 
	    q.push [:BLANK, tmp]
	  end
	  next
	end
	if tmp = sc.scan(/\A\n/)
	  q.push [:EOL, tmp] 
	  bol=true
	elsif tmp = sc.scan(/\A\w+:[A-Z]\w+(?!:)/)
	  q.push [:INTERWIKINAME, tmp]
	elsif tmp = sc.scan(PAT_URI) 
	  if URI::extract(tmp, ['http','https','ftp','news','mailto',]) != []
	    q.push [:URI, tmp]
	  else
	    q.push [:OTHER, tmp]
	  end
	# elsif tmp = sc.scan(/\A([A-Z][a-z]+){2,}\b/)
	elsif tmp = sc.scan(/\A([A-Z]+[a-z]+){2,}\b/)
	  q.push [:WIKINAME1, tmp]
	elsif tmp = sc.scan(/\A\[\[\S+?\]\]/)
	  q.push [:WIKINAME2, tmp]
#	elsif tmp = sc.scan(/\A={1,6} *$/)
#	  q.push [:HN_END, tmp]
	elsif tmp = sc.scan(/\A +\.$/)
	  q.push [:ENDPERIOD, tmp]
	elsif tmp = sc.scan(/\A[ \t\r\f]+/)
	  q.push [:SPACE, tmp]
	elsif tmp = sc.scan(/\A\|\| *$/)
	  q.push [:TABLE_END, tmp]
	elsif tmp = sc.scan(/\A\|\|/)
	  q.push [:TABLE, tmp]
	elsif tmp = sc.scan(/\A\[\S+ +\S+?\]/)
	  q.push [:MOINHREF, tmp]
	elsif tmp = sc.scan(/\A'''/)
	  q.push [:STRONG, tmp]
	elsif tmp = sc.scan(/\A''/)
	  q.push [:EM, tmp]
	elsif tmp = sc.scan(/\A[\w:]+/)
	  q.push [:WORD, tmp]
	elsif tmp = sc.scan(/\A[#{C128}-#{C255}]+/)
	  q.push [:OTHER, tmp]
	elsif tmp = sc.scan(/\A\S/e)
	  q.push [:OTHER, tmp]
	else
	  STDERR.puts sc.rest.inspect
	  raise 'must not happen'
	end
      end
      q.push [ :EOF, nil]
      return q
    end
  end
end

