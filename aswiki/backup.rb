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
    def rlog(name, rev=nil)
      log = []
      if rev
	command = "|rlog -zLT -r1.#{rev} #{backupname(name)}"
      else
	command = "|rlog -zLT #{backupname(name)}"
      end
      rev = 0
      File.foreach(command) do |l|
	if /^revision 1.(\d+)/ =~ l
	  rev = $1.to_i
	  next
	end
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);/ =~ l then
	 log << [rev, Time.parse($1)]
	end
      end
      return log
    end

    def co(name, rev)
      return File.readlines("|co -r1.#{rev} -p -q #{backupname(name)}")
    end

    def backup(fname)
      fname = quotemeta(fname)
      if ! system("ci -l -q -zLT #{fname} #{backupname(fname)}")
	raise
      end
    end

    def getrecentbackupdataandmtime(name)
      log = rlog(name)
      if log.length > 1
	f = co(name, log[1][0])
      else
	f = ''
      end
      return [f, log[1][1]] 
    end

    def getbackupdataandmtime(name, rev)
      return [co(name, rev), rlog(name, rev)[0][1]]
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
