require 'wwiki/backup'

module WWiki
  class Repository
    def initialize(dir)
      @dir = dir 
    end

    def read(name, id=nil) 
      return File.readlines(File.join(@dir,name))
    end
    
    def save(name, str)
      (open(File.join(@dir,name),'w') << str.gsub(/\r\n/, "\n")).close
    end
    
    def mtime(name)
      return File.mtime(File.join(@dir,name))
    end

    def namelist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f) )}
    end
    
    def attrlist
      return Dir.open(@dir).select{|f| test(?f, File.join(@dir, f) )}.
	map{|f| [f, mtime(f)]}
    end
  end
end
