require 'rubyunit'
require 'aswiki/backup.rb'

class TestAsWiki__Backup < RUNIT::TestCase

  def setup
    STDIN.reopen('/dev/null')
    @c = AsWiki::Backup.new('test')
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

  def test_ci
    fname = 'test/text/testbackup'
    bname = 'test/RCS/testbackup,v'
    s = "1\n"
    (open(fname ,'w') << s).close
    @c.ci(fname)
    # system("ci -l -q -zLT -d'2002/01/01 00:00:00' #{fname} #{bname}")
    # @c.ci('test/text/test')
    assert_equal(s, File.readlines("|co -p -q #{bname}").to_s)
  end

  def test_co
    fname = 'test/text/testbackup'
    bname = 'test/RCS/testbackup,v'
    s = "1\n"
    (open(fname ,'w') << s).close
    system("ci -l -q -zLT -d'2002/01/01 00:00:00' #{fname} #{bname}")
    @c.co('test/text/test',1)
    assert_equal(s, File.readlines("|co -p -q #{bname}").to_s)
  end

  def test_rlog
    data = @c.rlog('test')
    assert_equal([[2,Time.parse('2002/01/01 01:00:00')],
		   [1,Time.parse('2002/01/01 00:00:00')]] ,data)
  end

  def test_s_new
    assert_instance_of(AsWiki::Backup, @c)
  end

end

