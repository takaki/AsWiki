# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'bdb'

module AsWiki
  class AttachDB
    def initialize
      @env = BDB::Env.new("attach", BDB::CREATE|BDB::INIT_TRANSACTION,
			  {:set_lk_detect => BDB::LOCK_DEFAULT})
      @file = @env.open_db(BDB::Btree, "file", nil, BDB::CREATE)
      @time = @env.open_db(BDB::Btree, "time", nil, BDB::CREATE)
      @mime = @env.open_db(BDB::Btree, "mime", nil, BDB::CREATE)
      @name = @env.open_db(BDB::Btree, "name", nil, BDB::CREATE)
      @page = @env.open_db(BDB::Btree, "page", nil, BDB::CREATE)
    end
    def savefile(pname, attachedfile)
      begin
	@env.begin(@file, @time, @mime, @name, @page){|txn, db|
	  file, time, mime, name, page = db
	  max = file.keys.map{|k| k.to_i}.max
	  fname = (max ? max + 1 : 1).to_s
	  file[fname] = attachedfile.read
	  time[fname] = Time.now.to_i
	  page[fname] = pname
	  mime[fname] = attachedfile.content_type
	  name[fname] = attachedfile.original_filename
	  txn.commit
	}
      rescue BDB::LockDead
	txn.abort
	raise 
      end
    end
    def loadfile(num)
      begin
	ret = {}
	@env.begin(@file, @time, @mime, @name){|txn, db|
	  file, time, mime, name = db
	  ret =  {:mtime => Time.at(time[num].to_i),
	      :type => mime[num],
	      :body => file[num],
	    :filename => name[num]
	  }
	}
	return ret
      rescue BDB::LockDead
	txn.abort
	raise 
      end
    end
    def deletefile(num)
      begin
	@env.begin(@file, @time, @mime, @name, @page){|txn, db|
	  file, time, mime, name, page = db	
	  file.delete(num)
	  time.delete(num)
	  mime.delete(num)
	  name.delete(num)
	  page.delete(num)
	  txn.commit
	}
      rescue BDB::LockDead
	txn.abort
	raise 
      end
    end
    def listfile(pname)
      begin
	ret = []
	@env.begin(@page, @name){|txn, db|
	  page, name = db
	  ret = page.select{|key,value| value == pname}.map{|key,val| key}.
	    sort{|a,b| name[a] <=> name[b]}.collect{|f| 
	    {
	      :dllink => cgiurl([['c','download'],['num',f]]), 
	      :name   => name[f],
	      :rmlink => cgiurl([['c','delete'],['p',pname],['num',f]]),
	    }
	  }
	}
	return ret
      rescue BDB::LockDead
	txn.abort
	raise 
      end
    end
  end
end
