#! /usr/bin/ruby 
# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

load ('aswiki.conf')

require 'aswiki/config'
require 'cgi'

require 'aswiki/handler'
require 'aswiki/repository'
require 'aswiki/page'
require 'aswiki/exception'
require 'aswiki/pagedata'
require 'aswiki/cgi'
require 'aswiki/node'

if $USEATTACH
  require 'aswiki/attachdb'
end

require 'digest/md5'
require 'amrita/template'
require 'amrita/format'

if $0 == __FILE__ or defined?(MOD_RUBY)
  include AsWiki::Util
  Dir::chdir $BASEDIR
  Amrita::TemplateFileWithCache::set_cache_dir($DIR_CACHE)
  AsWiki::Node::load_parts_template
  repository = AsWiki::Repository.new
  Dir.glob("#$DIR_PLUGIN/*.rb").delete_if {|p| 
    p == "#$DIR_PLUGIN/attach.rb" and $USEATTACH == false
  }.each{|p| 
    require p.untaint  
  }

  cgi = CGI::new # XXX
  c    = (cgi.value('c')[0] or 'v')
  name = ((cgi.path_info and cgi.path_info[1..-1]) or 
	  cgi.value('p')[0] or $TOPPAGENAME)
  begin
    begin
      if AsWiki::HandlerTable.key?(c)
	AsWiki::HandlerTable[c].new(cgi, name)
      else
	raise AsWiki::RuntimeError, "Unknown Command or Not Active Feature '#{c}'\n"
      end
    rescue AsWiki::EditPageCall, AsWiki::SaveConflict
      AsWiki::HandlerTable[$!.class].new(cgi, $!)
    end
  rescue AsWiki::AsWikiError
    pd = AsWiki::PageData.new($!.class.to_s)
    pd.body = Amrita::pre { Amrita::e(:code) { $!.message + "\n"}  }
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', pd).to_s
    }
  rescue Exception
    pd = AsWiki::PageData.new('Program Error: ' + $!.class.to_s)
    pd.body = Amrita::pre { Amrita::e(:code) {
	$!.to_s + "\n" +  $!.backtrace.join("\n") # XXX pre
      }
    } 
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', pd).to_s
    }
  end    
end
