require 'strscan'
require 'uri/common'

module WWiki
  class Node
    def to_s
      return @text
    end
  end
  class WordNode
    def initialize(text)
      @text = text
    end
  end
  WORD  = [:SPACE, :OTHER, :WORD]
  TAG = [:ENDPERIOD, :INTERWIKINAME, :WIKINAME1, :WIKINAME2, :URI,:MOINHREF]
  DECORATION = [:B_DELIM, :I_DELIM]
  NORMALTEXT = WORD + TAG + [:EOL]
  TEXT = NORMALTEXT + DECORATION 
  PAT_URI =  /\A#{URI::REGEXP::PATTERN::X_ABS_URI}/xn
  C128 = [128].pack('C')
  C255 = [255].pack('C')

  class Scanner
    def initialize(content)
      @q = scan(content)
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
	  elsif tmp = sc.scan(/\A#end\s*$/)
	    q.push [:PLUGIN_END, tmp]
	  elsif tmp = sc.scan(/\A#.+$/)
	    q.push [:PLUGIN, tmp]
	  elsif tmp = sc.scan(/\A\s+\*/)
	    q.push [:UL, tmp]
	  elsif tmp = sc.scan(/\A\s+\(\d+\)/)
	    q.push [:OL, tmp]
	  elsif tmp = sc.scan(/\A\s+\+\s*/)
	    q.push [:DL, tmp]
	  elsif tmp = sc.scan(/\A\s+\S+?::\s*/)
	    q.push [:DL2, tmp]
	  elsif tmp = sc.scan(/\A={1,6}/)
	    q.push [:HN_BEGIN, tmp]
	  elsif tmp = sc.scan(/\A----\s*$/)
	    q.push [:HR, tmp]
	  elsif tmp = sc.scan(/\A\s*\|\|/)
	    q.push [:TABLE_BEGIN, tmp]
	  elsif tmp = sc.scan(/\A\{\{\{\s*$/)
	    q.push [:PRE_BEGIN, tmp]
	  elsif tmp = sc.scan(/\A\}\}\}\s*$/)
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
	elsif tmp = sc.scan(/\A([A-Z][a-z]+){2,}/)
	  q.push [:WIKINAME1, tmp]
	elsif tmp = sc.scan(/\A\[\[\S+?\]\]/)
	  q.push [:WIKINAME2, tmp]
	elsif tmp = sc.scan(/\A={1,6}\s*$/)
	  q.push [:HN_END, tmp]
	elsif tmp = sc.scan(/\A\s+\.$/)
	  q.push [:ENDPERIOD, tmp]
	elsif tmp = sc.scan(/\A[ \t\r\f]+/)
	  q.push [:SPACE, tmp]
	elsif tmp = sc.scan(/\A\|\|\s*$/)
	  q.push [:TABLE_END, tmp]
	elsif tmp = sc.scan(/\A\|\|/)
	  q.push [:TABLE, tmp]
	elsif tmp = sc.scan(/\A\[\S+\s+\S+?\]/)
	  q.push [:MOINHREF, tmp]
	elsif tmp = sc.scan(/\A'''/)
	  q.push [:B_DELIM, tmp]
	elsif tmp = sc.scan(/\A''/)
	  q.push [:I_DELIM, tmp]
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
    
  class Formatter
    def initialize(name, content) # String, String
      @name = name
      @wikilinks = []
      @q = scan(content)
      @line = 1
      # @tree = parse()
    end
    attr_reader :tree
    private 

    def parse
      node = []
      next_token
      while true
	if TEXT.include?(@token[0]) then node << text
	else 
	  case @token[0]
	  when :BLANK       
	    node << blank
	  when :DL          
	    node << dl
	  when :DL2         
	    node << dl2
	  when :EOL         
	    eol  
	    node << "\n"
	    
	  when :HN_BEGIN    
	    node << hn
	  when :HR          
	    node << "<hr>\n"  
	    next_token
	  when :PLUGIN      
	    node << plugin
	  when :PLUGIN_BEGIN
	    node << plugin_block
	  when :PRE_BEGIN   
	    node << preblock
	  when :TABLE_BEGIN 
	    node << table
	  when :UL          
	    node << ul.to_s
	  when :OL          
	    node << ol
	  when :EOF         
	    break
	  else 
	    node << syntax_error
	  end
	end 
      end
      return node
    end
    def blank
      node = []
      next_token
      while true
	case  @token[0]
	when :BLANK
	  next_token
	when :EOL  
	  eol
	else 
	  break
	end
      end
      return node  << "<p>"
    end
    def hn
      node = []
      text = []
      level = @token[1].size
      next_token
      text << textline
      if @token[0] == :HN_END 
	if level != @token[1].scan('=').size then text << @token[1]  end
	node << "<h#{level}>" << text << "</h#{level}>"
	next_token
      else
	if level >= 3  then node << "<h#{level}>" << text << "</h#{level}>"
	else                node << text
	end
      end
      return  node
    end
    def plugin_block
      node  = []
      block = [] << (@token[1]+"\n")
      block_b = @line
      if :EOL == next_token[0] then eol else node << syntax_error end
      block += textblock(:PLUGIN_END)
      while true
	case @token[0] 
	when :PLUGIN_END 
	  block << @token[1] 
	  next_token
	when :EOL 
	  eol 
	  break
	when :EOF
	  break
	else node << syntax_error
	end
      end
      block_e = @line 
      return node << @plugins.onview(@session, block, block_b, block_e)
    end
    def plugin
      node = @token[1]
      next_token
      return @plugins.onview(@session, [node.to_s], @line, 0)
    end

    def dl2
      node = [] << "<dl>" 
      while true
	node << "<dt>" << @token[1].split('::')[0].strip << "</dt>" 
	next_token
	node << "<dd>" << text << "</dd>"
	case @token[0]
	when :DL2
	  next_token
	  next
	when :EOF
	  break
	when :EOL
	  eol
	else  break
	end
      end
      return node << "</dl>"
    end
    def dl
      node = [] << "<dl>" 
      while true
	next_token
	node << "<dt>" << textline << "</dt>" <<"<dd>" << text  << "</dd>"
	case @token[0]
	when :DL 
	  next
	else node << "</dl>"
	  break
	end
      end
      return node 
    end
    def ul
      node = [] << "<ul>\n"
      depth = @token[1].size
      while true
	if @token[0] == :UL
	  if depth <= @token[1].size
	    node << li(depth)
	  else
	    break
	  end
	else 
	  break
	end
      end
      return node  << "</ul>\n"
    end
    def li(depth)
      node = []
      next_token
      node << "<li>" << text  
      if @token[0] == :UL && depth < @token[1].size
	node << ul
      end
      node << "</li>\n"
      return  node 
    end
    def ol
      node = [] << "<ol>"
      depth = @token[1].size
      next_token
      while true
	node << "<li>" << text
	case @token[0]
	when :OL
	  node << "</li>"
	  next_token
	when :EOL
	  eol
	else  break
	end
      end
      return node << "</li>" << "</ol>"
    end
    def table
      node = [] << "<table>" 
      while true
	case @token[0]
	when :TABLE_BEGIN
	  next_token
	  node << table_tr
	when :EOL
	  eol
	when :EOF
	  break
	else 
	  break
	end
      end
      node << '</table>'
      return node
    end
    def table_tr
      node = []
      node << "<tr>"
      while true
	node << table_td
	case @token[0]
	when :TABLE_END
	  eol
	  break  # XXX
	else 
	  break
	end
      end
      return node << "</tr>\n"
    end
    def table_td
      node = []
      while true
	node << "<td>" << text << "</td>"
	case @token[0]
	when :TABLE
	  next_token
	when :TABLE_END
	  break
	else  break
	end
      end
      return node
    end    
    def text
      node = []
      while true
	
	node << normaltext
	case @token[0]
	when :B_DELIM
	  node << decorate(:B_DELIM)
	when :I_DELIM
	  node << decorate(:I_DELIM)
	else  break
	end
      end
      return node
    end
    def normaltext
      node = []
      while true
	if NORMALTEXT.include?(@token[0]) then node << textline
	else break
	end
      end
      return node
    end
    def decorate(tag)
      next_token
      node = [] << D_TAG[tag][0] << normaltext
      if @token[0] == tag 
	node << D_TAG[tag][1]
	next_token
      else                
	node << D_TAG[tag][1] << syntax_error
      end
      return node 
    end

    def textline
      node = []
      while true
	case @token[0]
	when :OTHER, :SPACE, :WORD
	  node << WordNode(@token[1])
	when :WIKINAME1,:INTERWIKINAME
	  @wikilinks << @token[1]
	  node << wikihref(@token[1])
	when :WIKINAME2
	  name = @token[1][2..-3]
	  @wikilinks << name
	  node << wikihref(name)
	when :URI
	  node << ahref(@token[1],CGI::escapeHTML(@token[1]))
	when :MOINHREF
	  url, key = @token[1][1..-2].split
	  url = CGI::unescapeHTML(url)
	  if /\Aimg:/ =~ url then  node << %Q|<img src="#{$'}" alt="#{key}">|
	  else node << ahref(url, CGI::escapeHTML(key))
	  end
	when :ENDPERIOD
	  node << "<br>"
	when :EOL
	  eol
	  node << "\n" 
	  break
	else
	  break
	end
	next_token
      end
      return node
    end
    def textblock(endtag)
      node = []
      line = ""
      while true
	case @token[0]
	when :EOF   
	  break
	when :EOL   
	  line << "\n" 
	  node << line 
	  line = ""
	  eol 
	when endtag 
	  break
	else line << @token[1] 
	  next_token
	end
      end
      return node
    end
    def preblock
      node = [] << "<pre>"  
      next_token
      node += textblock(:PRE_END)
      while true
	case @token[0] 
	when :PRE_END 
	  node << "</pre>"
	  next_token
	  break
	when :EOF
	  break
	else syntax_error
	end
      end
      return node 
    end
    def eol
      @line +=1
      next_token
      return 
    end
    def syntax_error
      s = "(Syntax error at line #{@line}. ; #{@token.inspect})\n" 
	next_token 
      return s
    end
  end
end

