# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'time.rb'

module WWiki

  class Backup
    def initialize(basedir)
      @dir = File.join(basedir, 'RCS')
    end
    def quotemeta(s)
      return s.gsub(/(['"!$|;>*<\\&>()])/,'\\\\\1').untaint 
    end
    public
    def backup(fname)
      fname = quotemeta(fname)
      if ! system("ci -l -q -zLT -d #{fname} #{backupname(fname)}")
	raise
      end
    end
    def getrecentbackupdataandmtime(name)
      return nil if ! exist?(name);
      f = File.readlines("|co -p -q " + backupname(name))
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
      return nil if !exist?(name);
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
      return nil if !exist?(name);
      fn = backupname(name)
      mtime = nil
      f = File.readlines("|co -p -q -r1.#{id} #{fn}")
      File.foreach("|rlog -r1.#{id} -zLT #{fn}") do |l|
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	  mtime = $1
	  break
	end
      end
      return [f, Time.parse(mtime)]
    end

    private
    def exist?(name)
      File.exist?(backupname(name))
    end
    def backupname(fname)
      return File.join(@dir, File.basename(fname) + ',v')
    end
  end
end
