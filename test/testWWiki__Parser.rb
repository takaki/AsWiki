require 'rubyunit'
require 'aswiki/config.rb'
require 'aswiki/parser.rb'
load 'aswiki.conf'

class TestAsWiki__Parser < RUNIT::TestCase
  def test_tree
    s = ["aaa bbb ccc
 1.
 2.
"]
    t = []
    p =  AsWiki::Parser.new(s)
    # tree = p.tree
    # p tree.parsetree
    # assert_equal(t, tree.parsetree)
  end

  def test_s_new
    c = AsWiki::Parser.new('')
    assert_instance_of(AsWiki::Parser, c)
  end
  def test_html
    s = [" 
 * a
 * a
  * aa

 1. 1

 * aaa
  1. 11

 * aaa
 1. 1

 1. 1
   * aa
   * aa

 1. 1
  1. 11
"]
    p = AsWiki::Parser.new(s)
    # print p.tree.to_s
  end

end

