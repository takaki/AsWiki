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
      name = quotemeta(name)
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
      name = quotemeta(name)
      return File.readlines("|co -r1.#{rev} -p -q #{backupname(name)}")
    end

    def ci(name)
      name = quotemeta(name)
      if ! system("ci -l -q -zLT #{name} #{backupname(name)}")
	raise
      end
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
