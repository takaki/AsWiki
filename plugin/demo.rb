require 'wwiki/plugin'

module WWiki
  class NowPlugin < Plugin
    Name = 'now'
    def to_s
      return @val
    end
    def onview(line, b, e, av=[])
      @val = Time.now.to_s
    end
  end
end

module WWiki
  class PrintblockPlugin < Plugin
    Name = 'printblock'
    def to_s
      return @val
    end
    def onview(line, b, e, av=[])
      @val = line.map{|l| b=b+1 ;"#{b-1}: #{l}<br>\n" }.to_s 
    end
  end
end
