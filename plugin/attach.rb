# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'wwiki/plugin'
require 'cgi/session'
require 'bdb'

module WWiki
  class AttachPlugin < Plugin
    Name = 'attach'
    def onpost(session, file)
      pname = session['pname']
      mime = BDB::Btree.open("attach/mime.db", nil, BDB::CREATE)
      name = BDB::Btree.open("attach/name.db", nil, BDB::CREATE)
      page = BDB::Btree.open("attach/page.db", nil, BDB::CREATE)
      max = Dir.open('attach').select{|f| f =~ /\d+/}.collect{|f| f.to_i}.max
      fname = (max ? max + 1 : 1).to_s
      open("attach/#{fname}",'w') do |f|
	f.write(file[0].read)
	page[fname] = pname
	mime[fname] = file[0].content_type
	name[fname] = file[0].original_filename
	
      end
    end
    def onview(line, b, e, av=[])
      session = CGI::Session.new(CGI::new, {'tmpdir' => 'session'})
      session['pname'] = $pname
      session['plugin'] = self.type
      data ={:_session_id => session.session_id}
      form = load_template.expand(data)
      @view = form.to_s
    end
  end

  class AttachlistPlugin < Plugin
    Name = 'attachlist'
    def onpost(session, file)
      mime = BDB::Btree.open("attach/mime.db", nil, BDB::CREATE)
      name = BDB::Btree.open("attach/name.db", nil, BDB::CREATE)
      page = BDB::Btree.open("attach/page.db", nil, BDB::CREATE)
      max = Dir.open('attach').select{|f| f =~ /\d+/}.collect{|f| f.to_i}.max
      fname = (max ? max + 1 : 1).to_s
      open("attach/#{fname}",'w') do |f|
	f.write(file[0].read)
	page[fname] = pname
	mime[fname] = file[0].content_type
	name[fname] = file[0].original_filename
	
      end
    end
    def onview(line, b, e, av=[])
      mime = BDB::Btree.open("attach/mime.db", nil, BDB::CREATE)
      name = BDB::Btree.open("attach/name.db", nil, BDB::CREATE)
      page = BDB::Btree.open("attach/page.db", nil, BDB::CREATE)
      files =  page.select{|key,value| value == $pname}.collect{|key,val| key}
      item = files.collect{|f| name[f] + ' ' + mime[f]}
      data ={:item => item}
      form = load_template.expand(data)
      @view = form.to_s
    end
  end


end

