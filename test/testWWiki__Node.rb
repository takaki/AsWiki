require 'rubyunit'
require 'wwiki/node.rb'

class TestWWiki__Node < RUNIT::TestCase

  def test_parsetree
    # assert_fail("untested")
  end

  def test_to_s
    # assert_fail("untested")
    c = WWiki::LiNode.new
    c << "aaa" << "bbb"
    # print c.to_s
  end

  def test_s_new
    # assert_fail("untested")
  end

end

