require 'rubyunit'
require 'wwiki/parser.rb'

class TestWWiki__Parser < RUNIT::TestCase
  def test_tree
    s = ["aaa bbb
 *
 *
"]
    t = {WWiki::RootNode=>
      [
	{WWiki::TextNode=>
	  [
	    {WWiki::NormaltextNode=>
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
		{WWiki::NormaltextNode=>
		  [
		    {WWiki::TextlineNode=>["\n"]}
		  ]
		}
	      ]
	    },
	    {WWiki::TextNode =>
	      [
		{WWiki::NormaltextNode=>
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
    assert_equal(t, tree.parsetree)
  end

  def test_s_new
    c = WWiki::Parser.new('')
    assert_instance_of(WWiki::Parser, c)
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
