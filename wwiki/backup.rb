require 'time.rb'

module WWiki

=begin
  class Backup
      def initialize; raise; end
      def backup(fname) raise; end
      def getrecentbackupdataandmtime(name) raise; end
      def list_backups(name) raise; end
      def getbackupdataandmtime(name, id) raise; end
    end
  end
=end

  class Backup
    def initialize(dir)
      @backupdir = File.join(dir, 'RCS')
    end
    public
    def backup(fname)
      if ! system("ci -l -q -zLT -d #{fname} #{backupname(fname)}")
	raise
      end
    end
    def getrecentbackupdataandmtime(name)
      return nil if !existsbackupfile(name);
      f = File.readlines("|co -p -q " + backupname(name)).to_s
      mtime = ''
      File.foreach("|rlog -zLT " + backupname(name)) do |l|
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	  mtime = $1
	  break
	end
      end
      return [f, Time.parse(mtime)]
    end

    def list_backups(name)
      return nil if !existsbackupfile(name);
      n = []
      id = nil
      mtime = nil
      File.foreach("|rlog -zLT " + backupname(name)) do |l|
	if /^revision \d+\.(\d+)/ =~ l then
	  id = $1
	end
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	  mtime = $1
	  n << [id.to_i, Time.parse(mtime)]
	end
      end
      return n
    end
    def getbackupdataandmtime(name, id)
      return nil if !existsbackupfile(name);
      fn = backupname(name)
      mtime = nil
      f = File.readlines("|co -p -q -r1.#{id} #{fn}").to_s
      File.foreach("|rlog -r1.#{id} -zLT #{fn}") do |l|
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	  mtime = $1
	  break
	end
      end
      return [f, Time.parse(mtime)]
    end
    private
    def backupname(fname)
      return File.join(@backupdir, File.basename(fname) + ',v')
    end
    def existsbackupfile(name)
      test(?e, backupname(name).untaint)
    end
  end
end
