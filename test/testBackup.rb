require 'rubyunit'
require 'aswiki/backup.rb'

class TestAsWiki__Backup < RUNIT::TestCase

  def setup
    STDIN.reopen('/dev/null')
    @c = AsWiki::Backup.new('.')
    Dir.chdir('test')
    fname = 'text/test'
    bname = 'RCS/test,v'
    Dir.mkdir('RCS')
    Dir.mkdir('text')
    (open(fname ,'w') << "1\n").close
    system("ci -l -q -zLT -d'2002/01/01 00:00:00' #{fname} #{bname}")
    (open(fname ,'w') << "2\n").close
    system("ci -l -q -zLT -d'2002/01/01 01:00:00' #{fname} #{bname}")
  end
  def teardown
    Dir.glob('RCS/*').each{|f| File.unlink f}
    Dir.glob('text/*').each{|f| File.unlink f}
    Dir.rmdir('RCS')
    Dir.rmdir('text')
    Dir.chdir('..')
  end

  def test_ci
    fname = 'testbackup'
    bname = 'testbackup,v'
    s = "1\n"
    (open("text/#{fname}" ,'w') << s).close
    @c.ci(fname)
    # system("ci -l -q -zLT -d'2002/01/01 00:00:00' #{fname} #{bname}")
    # @c.ci('test/text/test')
    assert_equal(s, File.readlines("|co -p -q #{bname}").to_s)
  end

  def test_co
    fname = 'text/testbackup'
    bname = 'RCS/testbackup,v'
    s = "1\n"
    (open(fname ,'w') << s).close
    system("ci -l -q -zLT -d'2002/01/01 00:00:00' #{fname} #{bname}")
    s = @c.co('test',1).to_s
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

