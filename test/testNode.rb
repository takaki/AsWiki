require 'rubyunit'
require 'aswiki/node.rb'

class TestAsWiki__Node < RUNIT::TestCase

  def test_to_s
    # assert_fail("untested")
    c = AsWiki::Node.new('Li')
    c << "aaa" << "bbb"
    # print c.to_s
  end

  def test_s_new
    # assert_fail("untested")
  end

end

