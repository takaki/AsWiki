#! /usr/bin/ruby 
# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

$TOPPAGENAME = 'IndexPage'
$TIMEFORMAT  ="%F/%T %z"
$BASEDIR     = '.'
$USEBACKUP   = true
$USEATTACH   = true
$LANG        = 'ja'
$TITLE       = 'AsWiki'
$USERSS      = false
# $WIKINAMERE  = sc.scan(/\A([A-Z][a-z]+){2,}\b/) # original rule
$WIKINAMERE  = /\A([A-Z][a-z0-9]*){2,}\b/ # AsWiki local rule
$ATTACH_SIZE_LIMIT =  1024 * 1024 * 10
# $SAFE = 1
$CGIURL = "http://"+ENV['HTTP_HOST']+ENV['SCRIPT_NAME']

load ('aswiki.conf')

$metapages = {
  'MetaPages'   => '#metapages',
  'RecentPages' => '#recentpages',
  'AllPages'    => '#allpages',
  'OrphanedPages' => '#orphanedpages',
  'NotCreatedPages' => '#notcreatedpages',
  'PluginList' => '#pluginlist',
}

require 'cgi'

require 'aswiki/handler'
require 'aswiki/repository'
require 'aswiki/page'
require 'aswiki/exception'
require 'aswiki/pagedata'
require 'aswiki/cgi'

if $USEATTACH
  require 'aswiki/attachdb'
end

require 'digest/md5'
require 'amrita/template'
require 'amrita/format'



if $0 == __FILE__ or defined?(MOD_RUBY)
  include AsWiki::Util
  Dir::chdir $BASEDIR
  Amrita::TemplateFileWithCache::set_cache_dir('cache')
  AsWiki::Node::load_parts_template unless defined? $aswiki_parts_template_loaded
  $aswiki_parts_template_loaded = true
  repository = AsWiki::Repository.new('.')
  Dir.glob('plugin/*.rb').delete_if {|p| 
    p == 'plugin/attach.rb' and $USEATTACH == false
  }.each{|p| 
    require p.untaint  
  }

  cgi = FCGI.new
  c = cgi.value('c')[0]
  c = c.nil? ? 'v' : c
  name = cgi.value('p')[0]
  name = name.nil? ? $TOPPAGENAME : name
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
    pd = AsWiki::PageData.new($!.type.to_s)
    pd.body = Amrita::pre { Amrita::e(:code) { $!.message + "\n"}  }
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', pd).to_s
    }
  rescue Exception
    pd = AsWiki::PageData.new('Program Error: ' + $!.type.to_s)
    pd.body = Amrita::pre { Amrita::e(:code) {
	$!.to_s + "\n" +  $!.backtrace.join("\n") # XXX pre
      }
    } 
    cgi.out({'Status' => '200 OK', 'Content-Type' => 'text/html'}){
      AsWiki::Page.new('Error', pd).to_s
    }
  end    
end
