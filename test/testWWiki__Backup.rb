require 'rubyunit'
require 'wwiki/backup.rb'

class TestWWiki__Backup < RUNIT::TestCase

  def setup
    STDIN.reopen('/dev/null')
    @c = WWiki::Backup.new('test/RCS')
    fname = 'test/text/test'
    bname = 'test/RCS/test,v'
    Dir.mkdir('test/RCS')
    Dir.mkdir('test/text')
    (open(fname ,'w') << "1\n").close
    system("ci -l -q -zLT -d'2002/01/01 00:00:00' #{fname} #{bname}")
    (open(fname ,'w') << "2\n").close
    system("ci -l -q -zLT -d'2002/01/01 01:00:00' #{fname} #{bname}")
  end
  def teardown
    Dir.glob('test/RCS/*').each{|f| File.unlink f}
    Dir.glob('test/text/*').each{|f| File.unlink f}
    Dir.rmdir('test/RCS')
    Dir.rmdir('test/text')
  end
  def test_backup
    fname = 'test/text/testbackup'
    bname = 'test/RCS/testbackup,v'
    s = "1\n"
    (open(fname ,'w') << s).close
    system("ci -l -q -zLT -d'2002/01/01 00:00:00' #{fname} #{bname}")
    @c.backup('test/text/test')
    assert_equal(s, File.readlines("|co -p -q #{bname}").to_s)
  end

  def test_getbackupdataandmtime
    data = @c.getbackupdataandmtime('test',1)
    assert_equal([["1\n"],Time.parse('2002/01/01 00:00:00')] ,data)
  end

  def test_getrecentbackupdataandmtime
    data = @c.getrecentbackupdataandmtime('test')
    assert_equal([["2\n"],Time.parse('2002/01/01 01:00:00')] ,data)
  end

  def test_list_backups
    data = @c.list_backups('test')
    assert_equal([[2,Time.parse('2002/01/01 01:00:00')],
		   [1,Time.parse('2002/01/01 00:00:00')]] ,data)
		 
  end

  def test_s_new
    assert_instance_of(WWiki::Backup, @c)
  end

end

