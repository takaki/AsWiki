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
    TEXTLINE = WORD + TAG + [:EOL]
    PLAINTEXT = TEXTLINE + DECORATION 
    ELEMENT = PLAINTEXT + [:UL, :OL]
    D_TAG = {:EM => 'Em' ,  :STRONG => 'Strong'}

    class DummyNode < Node
      def expand
      end
    end
    
    def initialize(str,name='', maketree=true)
      @name = name
      @s = Scanner.new(str)
      @rawwikinames = []
      @plugin = AsWiki::Plugin.new(@name)
      @nodeclass =  maketree ? Node : DummyNode

      @tree = parse
    end
    attr_reader :tree
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
      node = @nodeclass.new('Root')
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
	  node << @nodeclass.new('Hr').expand
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
      return node.expand
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
      node = @nodeclass.new("H#{level}")
      next_token
      node << textline
      return node.expand
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
      node = @nodeclass.new('Dl')
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
      return node.expand
    end
    def ul
      node = @nodeclass.new('Ul')
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
      return node.expand
    end
    def ol
      node = @nodeclass.new('Ol')
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
      return node.expand
    end
    def table
      node = @nodeclass.new('Table')
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
      return node.expand
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
      node = @nodeclass.new('Paragraph')
      node << plaintext
      return node.expand
    end
    def plaintext
      node = @nodeclass.new('Plaintext')
      while true
	case @token[0]
	when *TEXTLINE
	  node << textline
	when :STRONG
	  node << decorate(:STRONG)
	when :EM
	  node << decorate(:EM)
	else
	  break
	end
      end
      return node.expand
    end
    def element(indent=0)
      node = @nodeclass.new('Element')
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
	    throw :ulend, node.expand
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
      return node.expand
    end
    def decorate(tag)
      next_token
      node = @nodeclass.new(D_TAG[tag])
      node  << textline
      if @token[0] == tag 
	next_token
      else                
	node << syntax_error
      end
      return node.expand
    end

    def textline
      node = @nodeclass.new('Textline')
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
	  node << Amrita::e(:a, Amrita::a(:href, @token[1])){@token[1]}
	when :MOINHREF
	  url, key = @token[1][1..-2].split
	  if /\Aimg:/ =~ url 
	    node << Amrita::e(:img, Amrita::a(:src,$'), #' this commet is for emacs ruby-mode
			      Amrita::a(:alt,key))
	  else
	    node << Amrita::e(:a, Amrita::a(:href,url),
			      Amrita::a(:class, 'external')
			      ){key}
	  end
	when :ENDPERIOD
	  node << Amrita::e(:br)
	when :EOL
	  node << "\n"
	  eol
	  break
	else
	  break
	end
	next_token
      end
      return node.expand
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

