# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'wwiki/backup'
require 'wwiki/util'


module WWiki
  class Repository
    def initialize(basedir='.')
      @dir = File.join(basedir ,'text')
      @basedir = basedir
    end

    def exist?(name)
      return File.exist?(textname(name))
    end

    def load(name, id=nil) 
      return File.readlines(textname(name))
    end
    
    def save(name, str)
      if exist?(name)
	backup = WWiki::Backup.new(@basedir)
	backup.backup(textname(name))
      end
      (open(textname(name),'w') << str.gsub(/\r\n/, "\n")).close
    end
    
    def mtime(name)
      if exist?(name)
	return File.mtime(textname(name))
      else
	return nil
      end
    end

    def namelist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f))}.
	map{|f| WWiki::unescape(f)}
    end
    
    def attrlist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f))}.
	map{|f| [WWiki::unescape(f), File.mtime(File.join(@dir, f))]}
    end
    private
    def textname(name)
      return File.join(@dir, WWiki::escape(name))
    end
  end
end
