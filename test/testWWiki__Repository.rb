require 'rubyunit'

require 'wwiki/repository.rb'

require 'wwiki/util'

class TestWWiki__Repository < RUNIT::TestCase

  def setup
    STDIN.reopen('/dev/null')
    @c = WWiki::Repository.new('test')
    @dir = 'test/text'
    @fname = ['test', 'test2','日本語']
    Dir.mkdir('test/RCS')
    Dir.mkdir('test/text')
    @fname.each{|f| (open(File.join(@dir,WWiki::escape(f)) ,'w') << "1\n").close  }
  end
  def teardown
    Dir.glob('test/text/*').each{|f| File.unlink f}
    Dir.rmdir('test/text')
    Dir.glob('test/RCS/*').each{|f| File.unlink f}
    Dir.rmdir('test/RCS')
  end
  
  def test_attrlist
    assert_equal(@fname.map{|f| [f, File.mtime(File.join(@dir,WWiki::escape(f)))]}.sort,
		 @c.attrlist.sort)
  end

  def test_mtime
    assert_equal(File.mtime('test/text/test'), @c.mtime('test'))
    assert_equal(File.mtime('test/text/%C6%FC%CB%DC%B8%EC'), @c.mtime('日本語'))
  end

  def test_namelist
    assert_equal(@fname.sort, @c.namelist.sort)
  end

  def test_read
    assert_equal(["1\n"],@c.read('test'))
  end

  def test_save
    @c.save('test2',"1\r\n2")
    assert_equal(["1\n","2"], File.readlines('test/text/test2'))
  end

  def test_s_new
    assert_instance_of(WWiki::Repository,@c)
  end

end

