require 'rubyunit'
require 'wwiki/parser.rb'

class TestWWiki__Parser < RUNIT::TestCase
  def test_tree
    s = ["aaa bbb ccc
 *
 *
"]
    t = {WWiki::RootNode=>
      [
	{WWiki::TextNode=>
	  [
	    {WWiki::ParagraphNode=>
	      [
		{WWiki::TextlineNode=>["aaa", " ", "bbb", "\n"]
		}
	      ]
	    }
	  ]
	}, 
	{WWiki::UlNode =>
	  [
	    {WWiki::TextNode =>
	      [
		{WWiki::ParagraphNode=>
		  [
		    {WWiki::TextlineNode=>["\n"]}
		  ]
		}
	      ]
	    },
	    {WWiki::TextNode =>
	      [
		{WWiki::ParagraphNode=>
		  [
		    {WWiki::TextlineNode=>["\n"]}
		  ]
		}
	      ]
	    },
	  ]
	}
      ]
    }
    p =  WWiki::Parser.new(s)
    tree = p.tree
    # p tree.parsetree
    # assert_equal(t, tree.parsetree)
  end

  def test_s_new
    c = WWiki::Parser.new('')
    assert_instance_of(WWiki::Parser, c)
  end
  def test_html
    s = ["aaa bbb ccc
 *
 *
"]
    p = WWiki::Parser.new(s)
    p p.tree.to_s
  end

end

=begin
    a = "abc cde fgh
WikiName
[[wikiname2]]
Tiki:WelcomVisitors
「日本語」
http://www.jp/index.cgi
[http://todo.org/ Tiki]
 .
"
    d = " * f
  * ff
   * fff
  * ff
 * f
"  
    e = " + foo
about fffoo
 + bar
about barbar"

    f = "  foo::foofoo
  bar:: barbar"
    g = "#plugin hoge foo bar"
    h = "#begin plugin foo
111
222
333
#end"
    i = "{{{
a
b
c
}}}"

    j = "[[[[[ [[[[ [[[ 1 ]]] [[[ ''2'' ]]] ]]]]
[[[[ [[[ [[SandBox]] ]]] [[[ [http://www/ wwwserver] ]]] ]]]]
]]]]]"

    k ="br
.
no
br .
no.
"
    l = "
 * a
  * b
 * a

=end
