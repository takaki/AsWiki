require 'rubyunit'
require 'aswiki/util.rb'

class TestAsWiki__Util < RUNIT::TestCase
  class UtilClass
    include AsWiki::Util
  end
  def setup
    @c = UtilClass.new
  end
  def test_cgiurl
    #assert_fail("untested")
  end

  def test_pathexpand
    assert_equal(['foo'], @c.pathexpand(['foo']))
    assert_equal(['foo','bar'], @c.pathexpand(['foo','..','foo','bar']))
    assert_equal(['bar'], @c.pathexpand(['foo','..','bar']))
    assert_equal(['foo','bar'], @c.pathexpand(['foo','.','bar']))
  end

  def test_expandwikiname
    assert_equal('foo', @c.expandwikiname('foo'))
    assert_equal('bar/foo', @c.expandwikiname('./foo','bar'))
    assert_equal('foo', @c.expandwikiname('foo','bar'))
    assert_equal('foo/bar/baz', @c.expandwikiname('./baz','foo/bar'))
    assert_equal('foo/bar', @c.expandwikiname('../bar','foo/bar'))
    assert_equal('foo', @c.expandwikiname('foo','foo/bar'))

    assert_equal('a//c', @c.expandwikiname('c','a//b'))
    assert_equal('a//b/c', @c.expandwikiname('./c','a//b'))
    assert_equal('a//c', @c.expandwikiname('../c','a//b'))
    assert_equal('a//b//d', @c.expandwikiname('../d','a//b//c'))
    assert_equal('a//b//c/d', @c.expandwikiname('./d','a//b//c'))
    assert_equal('d', @c.expandwikiname('//d','a//b//c'))
    assert_equal('d//e', @c.expandwikiname('//d//e','a//b//c'))

    assert_equal('c', @c.expandwikiname('c','a//'))
  end

  def test_modified
    #assert_fail("untested")
  end

  def test_timestr
    #assert_fail("untested")
  end

  def test_wikilink
    #assert_fail("untested")
  end

end

