# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'time.rb'

module AsWiki

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
      found = false
      head  = 1
      mtimestr = '0'
      # return nil if ! exist?(name);
      File.foreach("|rlog -zLT " + backupname(name)) do |l|
	if l =~ /^head: 1.(\d+)/
	  head = $1.to_i
	end
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	  if found
	    mtimestr = $1
	    break
	  else
	    found = true
	  end
	end
      end
      if head != 1
	f = File.readlines("|co -r1.#{head-1} -p -q " + backupname(name))
      else
	f = ''
      end
      return [f, Time.parse(mtimestr)]
    end

    def list_backups(name)
      return nil if !exist?(name);
      n = []
      id = nil
      mtimestr = nil
      File.foreach("|rlog -zLT " + backupname(name)) do |l|
	if /^revision \d+\.(\d+)/ =~ l then
	  id = $1
	end
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	  mtimestr = $1
	  n << [id.to_i, Time.parse(mtimestr)]
	end
      end
      return n
    end
    def getbackupdataandmtime(name, id)
      return nil if !exist?(name);
      fn = backupname(name)
      mtimestr = nil
      f = File.readlines("|co -p -q -r1.#{id} #{fn}")
      File.foreach("|rlog -r1.#{id} -zLT #{fn}") do |l|
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	  mtimestr = $1
	  break
	end
      end
      return [f, Time.parse(mtimestr)]
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
