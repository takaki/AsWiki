# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'strscan'
require 'uri/common'
require 'delegate'

# require 'obaq/htmlgen'

require 'aswiki/scanner'
require 'aswiki/node'
require 'aswiki/util'
require 'aswiki/plugin'

module AsWiki
  class Parser
#    include Obaq::HtmlGen
    include AsWiki::Util
    WORD  = [:SPACE, :OTHER, :WORD]
    TAG = [:ENDPERIOD, :INTERWIKINAME, :WIKINAME1, :WIKINAME2, :URI,:MOINHREF]
    DECORATION = [:EM, :STRONG]
    ESCAPE = [:ESCAPE_BEGIN, :ESCAPE_END]
    TEXTLINE = WORD + TAG + [:EOL]
    PLAINTEXT = TEXTLINE + DECORATION + ESCAPE
    ELEMENT = PLAINTEXT + [:UL, :OL]
    D_TAG = {:EM => 'Em' ,  :STRONG => 'Strong'}

    def initialize(str,name='')
      @name = name
      @s = Scanner.new(str)
      @rawwikinames = []
      @plugin = AsWiki::Plugin.new(@name)
      
      # @nodeclass =  maketree ? Node : DummyNode
      @tocdata = []
      @tocnum  = 0

      @tree = parse
    end
    attr_reader :tree, :tocdata
    def wikinames
      @rawwikinames.collect{|n|
	expandwikiname(n,@name)
      }
    end

    private 
    def next_token
      @token = @s.next_token
    end
    def parse
      @line = 1
      node = Node.new('Root')
      next_token
      while true
	case @token[0]
	when *PLAINTEXT
	  node << paragraph
	when :UL
	  node << ul
	when :OL
	  node << ol
	when :BLANK       
	  node << blank
	when :DL          
	  node << dl
	when :EOL         
	  eol  
	  node << "\n"
	when :HN_BEGIN    
	  node << hn
	when :HR          
	  node << Node.new('Hr')
	  next_token
	when :PLUGIN  
	  node << plugin
	when :PLUGIN_BEGIN
	  node << plugin_block
	when :PRE_BEGIN   
	  node << preblock
	when :TABLE_BEGIN 
	  node << table
	when :EOF         
	  break
	else 
	  node << syntax_error
	end
      end 
      return node
    end
    def blank
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
      return "\n"
    end
    def hn
      level = @token[1].size
      node = Node.new("H#{level}")
      next_token
      ret = textline
      if level == 2
	@tocnum = @tocnum + 1
	@tocdata << {:number => "##{@tocnum}", :text => ret}
	node << {:number => @tocnum, :text=> ret}
      else
	node << {:number => nil, :text=> ret}
      end
      return node
    end
    def plugin_block
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
      return @plugin.onview(block, block_b, block_e)
    end
    def plugin
      node = @token[1]
      next_token
      return @plugin.onview(node.to_a, @line, 0)
    end

    def dl
      node = Node.new('Dl')
      while true
	next_token
	node << { :title => textline,  :doc => element}
	case @token[0]
	when :DL 
	  next
	else
	  break
	end
      end
      return node
    end
    def ul
      node = Node.new('Ul')
      indent = @token[1].size
      next_token
      node << catch(:ulend) do
	while true
	  case @token[0]
	  when *ELEMENT
	    node << element(indent)
	  else
	    break
	  end
	end
      end
      return node
    end
    def ol
      node = Node.new('Ol')
      indent = @token[1].size
      next_token
      while true
	case @token[0]
	when *ELEMENT
	  node << element(indent)
	else
	  break
	end
      end
      return node
    end
    def table
      node = Node.new('Table')
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
      return node
    end
    def table_tr
      col = []
      while true
	col << plaintext
	case @token[0]
	when :TABLE_END
	  eol
	  break  # XXX
	when :TABLE
	  next_token
	  next
	else 
	  break
	end
      end
      return {:col => col}
    end
    def paragraph
      node = Node.new('Paragraph')
      node << plaintext
      return node
    end
    def plaintext
      node = Node.new('Plaintext')
      while true
	case @token[0]
	when *TEXTLINE
	  node << textline
	when :ESCAPE_BEGIN
	  next_token
	  ret  = textblock(:ESCAPE_END)
	  next_token
	  node << ret
	when :ESCAPE_END
	  node << @token[1]
	  next_token
	when :STRONG
	  node << decorate(:STRONG)
	when :EM
	  node << decorate(:EM)
	else
	  break
	end
      end
      return node
    end
    def element(indent=0)
      node = Node.new('Element')
      while true
	case @token[0]
	when *PLAINTEXT
	  node << plaintext
	when :UL
	  if indent == @token[1].size
	    next_token
	    break
	  elsif indent < @token[1].size
	    node << ul
	  elsif indent > @token[1].size
	    throw :ulend, node
	  else
	    raise RangeError
	  end
	when :OL          
	  if indent == @token[1].size
	    next_token
	    break
	  elsif indent < @token[1].size
	    node << ol
	  elsif indent > @token[1].size
	    break
	  else
	    raise RangeError
	  end
	else
	  break
	end
      end
      return node
    end
    def decorate(tag)
      next_token
      node = Node.new(D_TAG[tag])
      node  << textline
      if @token[0] == tag 
	next_token
      else                
	node << syntax_error
      end
      return node
    end

    def textline
      node = Node.new('Textline')
      while true
	case @token[0]
	when :OTHER, :SPACE, :WORD
	  node << @token[1]
	when :WIKINAME1,:INTERWIKINAME
	  @rawwikinames << @token[1]
	  node << wikilink(@token[1], @name)
	when :WIKINAME2
	  name = @token[1][2..-3]
	  @rawwikinames << name 
	  node << wikilink(name, @name)
	when :URI
	  tn = Node.new('Url')
	  tn << {:url=>@token[1],:text=>@token[1]}
	  node << tn
	when :MOINHREF
	  url, key = @token[1][1..-2].split(/\s+/, 2)
	  if /\Aimg:(http|https)/ =~ url  # XXX
	    tn = Node.new('MoinhrefImg')
	    tn << {:url => $1 + $', :alt => key}
	    node << tn
	  else
	    tn = Node.new('Moinhref')
	    tn << {:url => url, :text => key}
	    node << tn
	  end
	when :ENDPERIOD
	  node << Node.new('Br')
	when :EOL
	  node << "\n"
	  eol
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
	  if not line.empty?
	    node << line
	  end
	  break
	else line << @token[1] 
	  next_token
	end
      end
      return node
    end
    def preblock
      next_token
      ret = Amrita::e(:pre, :class=>"code") { Amrita::CompactSpace.new(false) { textblock(:PRE_END).join  } } # XXX use template ???
      next_token # XXX
      return ret 
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

