require 'rubyunit'
require 'wwiki/repository.rb'

class TestWWiki__Repository < RUNIT::TestCase

  def setup
    @c = WWiki::Repository.new('test/data')
    @dir = 'test/data'
    @fname = ['test', 'test2']
    Dir.mkdir('test/data')
    @fname.each{|f| (open(File.join(@dir,f) ,'w') << "1\n").close }
  end
  def teardown
    Dir.glob('test/data/*').each{|f| File.unlink f}
    Dir.rmdir('test/data')
  end
  
  def test_attrlist
    
    assert_equal(@fname.map{|f| [f, File.mtime(File.join(@dir,f))]}.sort,
		 @c.attrlist.sort)
  end

  def test_mtime
    assert_equal(File.mtime('test/data/test'), @c.mtime('test'))
  end

  def test_namelist
    assert_equal(@fname.sort, @c.namelist.sort)
  end

  def test_read
    assert_equal(["1\n"],@c.read('test'))
  end

  def test_save
    @c.save('test2',"1\r\n2")
    assert_equal(["1\n","2"], File.readlines('test/data/test2'))
  end

  def test_s_new
    assert_instance_of(WWiki::Repository,@c)
  end

end

