require 'rubyunit'
require 'wwiki/scanner.rb'

class TestWWiki__Scanner < RUNIT::TestCase

  def test_next_token
    t = [ 
      ["=== ===", [[:HN_BEGIN, "==="],[:SPACE, " "], [:HN_END, "==="]]],
      ["AA:BB:CC", [[:OTHER, "AA:BB:CC"]]],
      ["hoge  ", [[:WORD, "hoge"],[:SPACE, "  "]]],
      ["foo" , [[:WORD, 'foo']]],
      ["a http://f.b.jp:80/cgi-bin/tiki.cgi?c=v",[[:WORD, 'a'], 
	  [:SPACE, ' '],[:URI, 'http://f.b.jp:80/cgi-bin/tiki.cgi?c=v']]],
      ["a mailto:hoge@foo.bar",[[:WORD, 'a'], 
	  [:SPACE, ' '],[:URI, 'mailto:hoge@foo.bar']]],
      ["#begin foo", [[:PLUGIN_BEGIN, '#begin foo']]],
      ["#end  ", [[:PLUGIN_END, '#end  ']]],
      ["#plugin", [[:PLUGIN, "#plugin"]]],
      [".", [[:ENDPERIOD, '.']]],
      [". ", [[:OTHER, '.'],[:SPACE, ' ']]],
      ["{{{", [[:PRE_BEGIN, '{{{']]],
      ["}}}", [[:PRE_END, '}}}']]],
      [" {{{", [[:SPACE, " "], [:OTHER,'{'],[:OTHER,'{'],[:OTHER,'{'],]],
      ["|| ||", [[:TABLE_BEGIN, '||'],[:SPACE, " "], [:TABLE_END,'||']]],
      ["WikiName", [[:WIKINAME1,"WikiName"]]],
      ["[[wikiname]]", [[:WIKINAME2,"[[wikiname]]"]]],
      ["hoge:WikiName", [[:INTERWIKINAME,"hoge:WikiName"]]],
      ["[http://hoge.foo/ foolink]", 
	[[:MOINHREF, '[http://hoge.foo/ foolink]']]],
      ["'' ''", [[:I_DELIM, "''"],[:SPACE, ' '],[:I_DELIM, "''"]]],
      ["'''a'''", [[:B_DELIM, "'''"],[:WORD, 'a'],[:B_DELIM, "'''"]]],
      ["''a'' '''b'''", [[:I_DELIM, "''"],[:WORD, 'a'],[:I_DELIM, "''"],
	  [:SPACE, ' '],[:B_DELIM, "'''"],[:WORD, 'b'],[:B_DELIM, "'''"]]],
      [" (1) hoge", [ [:OL, ' (1)'],[:SPACE, ' '],[:WORD, 'hoge']]],
      [" * hoge", [ [:UL, ' *'],[:SPACE, ' '],[:WORD, 'hoge']]],
      [" ** hoge", [[:UL, ' *'],[:OTHER, '*'],[:SPACE, ' '],[:WORD, 'hoge']]],
      [" + hoge", [ [:DL, ' + '],[:WORD, 'hoge']]],
      [":ABC", [[:WORD, ":ABC"]]],
      [" ** [http://www/ www]", [[:UL, " *"],[:OTHER, '*'],[:SPACE, ' '],[:MOINHREF, "[http://www/ www]"] ]],
      ["{[}]", [[:OTHER, "{"],[:OTHER, "["],[:OTHER, "}"],[:OTHER, "]"],]],
      ["日本語WikiName", [[:OTHER, "日本語"], [:WIKINAME1, "WikiName"]]],
      ["WikiName日本", [[:WIKINAME1,"WikiName"],[:OTHER, "日本"]]],
      ["日本語[[foo]]", [[:OTHER, "日本語"], [:WIKINAME2, "[[foo]]"]]],
      ["@@@[[foo]]", [[:OTHER, "@"], [:OTHER, "@"], [:OTHER, "@"], [:WIKINAME2, "[[foo]]"]]],
      ]
    
    s = WWiki::Scanner.new(" \n")
    q = []
    while i =  s.next_token
      q << i
    end
    assert_equal([[:BLANK, ' '],[:EOL,"\n"],[:EOF,nil]], q)
    t.each{|a,r| 
      s = WWiki::Scanner.new(a+"\n")
      q = []
      while i =  s.next_token
	q << i
      end
      assert_equal(r, q[0..-3])
    }
  end

  def test_s_new
    c = WWiki::Scanner.new('')
    assert_instance_of(WWiki::Scanner, c)
  end

end

