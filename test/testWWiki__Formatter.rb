require 'rubyunit'
require '../wwiki/formatter.rb'

class TestWWiki__Formatter < RUNIT::TestCase
  def setup
    @c = WWiki::Formatter.new(nil, nil)
  end


  def test_s_new
    assert_instance_of(WWiki::Formatter,@c)
  end

end

=begin
class TestPageFormatter < RUNIT::TestCase
  def setup
    @c = PageFormatter.new(nil, nil)
  end
  def test_evaluate
    a = "abc cde fgh
WikiName
[[wikiname2]]
Tiki:WelcomVisitors
「日本語」
http://www.jp/index.cgi
[http://todo.org/ Tiki]
 .
"
    b = "''iii
'' '''bbb'''"

    c = "[[[[[ [[[[ [[[ '''a''' ]]] [[[ b ]]] ]]]] 
[[[[ [[[ 1 ]]] [[[ 2 ]]] ]]]] ]]]]]"
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
"

    @c = PageFormatter.new(Tiki.new, l)
    # @c = PageFormatter.new(nil, File.readlines('../cgi-bin/text/TikiSandBox'))
    puts
    puts @c.evaluate()
  end
  def test_s_new
    assert_instance_of(NewPageFormatter, @c)
  end

end
=end
