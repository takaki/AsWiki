# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2.

require 'aswiki/plugin'
require 'cgi/session'
require 'bdb'

module AsWiki
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
      session = CGI::Session.new(CGI::new, {'tmpdir' => 'session',
				   'new_session'=>true})
      session['pname'] = @name
      session['plugin'] = self.type

      mime = BDB::Btree.open("attach/mime.db", nil, BDB::CREATE)
      name = BDB::Btree.open("attach/name.db", nil, BDB::CREATE)
      page = BDB::Btree.open("attach/page.db", nil, BDB::CREATE)

      files =  page.select{|key,value| value == @name}.collect{|key,val| key}
      item = files.sort{|a,b| name[a] <=> name[b]}.collect{|f| {
	  :dllink => $CGIURL + "?c=download;num=#{f}", 
	  # :name => CGI::escapeHTML( name[f]) ,
	  :name => name[f],
	  :rmlink => $CGIURL + "?c=delete;p=#{CGI::escape(@name)};num=#{f}", 
	} }

      data ={:_session_id => session.session_id,
	:item => item
      }
      @view = load_template.expand_tree(data)
    end
  end
end

