require 'strscan'
require 'uri/common'
require 'delegate'

require 'obaq/htmlgen'

require 'wwiki/scanner'
require 'wwiki/node'
require 'wwiki/util'

module WWiki
  class Parser
    include Obaq::HtmlGen
    WORD  = [:SPACE, :OTHER, :WORD]
    TAG = [:ENDPERIOD, :INTERWIKINAME, :WIKINAME1, :WIKINAME2, :URI,:MOINHREF]
    DECORATION = [:EM, :STRONG]
    TEXTLINE = WORD + TAG + [:EOL]
    PLAINTEXT = TEXTLINE + DECORATION 
    ELEMENT = PLAINTEXT + [:UL, :OL]
    D_TAG = {:EM => 'Em' ,  :STRONG => 'Strong'}
    
    def initialize(str)
      @s = Scanner.new(str)
      @tree = parse
    end
    attr_reader :tree
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
      node << textline
      return  node
    end
    def plugin_block
      node  = nil
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
	    throw :ulend, node # XXX ???
	  else
	    raise
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
	    raise
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
	  node << E(:a, A(:href, $CGIURL + '?c=v&p=' + WWiki::escape(@token[1]))
		    ) {@token[1]}
	when :WIKINAME2
	  name = @token[1][2..-3]
	  node << E(:a, A(:href, $CGIURL + '?c=v&p=' + name)){name}
	when :URI
	  node << E(:a, A(:href, @token[1])){@token[1]}
	when :MOINHREF
	  url, key = @token[1][1..-2].split
	  if /\Aimg:/ =~ url 
	    node << E(:img, A(:src,$'), A(:alt, key))
	  else
	    node << E(:a, A(:href, url)){key}
	  end
	when :ENDPERIOD
	  node << E(:br)
	when :EOL
	  eol
	  # node << "\n" 
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
	  next_token
	  break
	else line << @token[1] 
	  next_token
	end
      end
      return node
    end
    def preblock
      node = Node.new('Pre')
      next_token
      node << textblock(:PRE_END).to_s
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

