# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'time.rb'
require 'aswiki/util.rb'

module AsWiki
  class RCSBackup
    def initialize(dir=$DIR_RCS)
      @dir = dir
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
      File.foreach(command.untaint) do |l|
	if /^revision 1.(\d+)/ =~ l
	  rev = $1.to_i
	  next
	end
	if /^date: (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\+\d\d);(?:.*lines: (.+)?)?/ =~ l
	 log << [rev, Time.parse($1), $2]
	end
      end
      return log
    end

    def co(name, rev)
      return File.readlines("|co -r1.#{rev} -zLT -p -q #{backupname(name)}".untaint)
    end

    def ci(name)
      # if ! system("ci -l -q -zLT #{textname(name)} #{backupname(name)}")
      if ! system("ci -l -q -zLT  #$DIR_TEXT/#{AsWiki::escape(name)} #{backupname(name)}".untaint) # XXX XXX XXX
	raise IOError, name
      end
    end

    private
    def exist?(name)
      File.exist?(backupname(name))
    end
    def backupname(fname)
      return File.join(@dir, AsWiki::escape(fname) + ',v')
    end
  end

  class NullBackup
    def initialize(basedir)
    end
    public

    def ci(name)
    end
  end
  
  
  if $USEBACKUP
    Backup = RCSBackup
  else
    Backup = NullBackup
  end
end
