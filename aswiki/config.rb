# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

# STDERR.puts 'load config'

$TOPPAGENAME = ($TOPPAGENAME or 'IndexPage')
$TITLE       = ($TITLE       or 'AsWiki')
$BASEDIR     = ($BASEDIR     or '.')
$WIKINAMERE  = ($WIKINAMERE  or Regexp.new(/\A(?:[A-Z][a-z]+){2,}\b/))
$LANG        = ($LANG        or 'ja')
$TIMEFORMAT  = ($TIMEFORMAT  or "%Y-%m-%d/%H:%M:%S %z")

$USEBACKUP   = (defined?($USEBACKUP) ? $USEBACKUP : true)
$USERSS      = (defined?($USERSS)    ? $USERSS    : true)
$USEATTACH   = (defined?($USEATTACH) ? $USEATTACH : false)

$ATTACH_SIZE_LIMIT = ($ATTACH_SIZE_LIMIT or  1024 * 1024 * 10)

$DIR_RCS      = ($DIR_RCS      or File.join($BASEDIR, 'RCS'))
$DIR_ATTACH   = ($DIR_ATTACH   or File.join($BASEDIR, 'attach'))
$DIR_CACHE    = ($DIR_CACHE    or File.join($BASEDIR, 'cache'))
$DIR_PLUGIN   = ($DIR_PLUGIN   or File.join($BASEDIR, 'plugin'))
$DIR_SESSION  = ($DIR_SESSION  or File.join($BASEDIR, 'session'))
$DIR_TEMPLATE = ($DIR_TEMPLATE or File.join($BASEDIR, 'template'))
$DIR_TEXT     = ($DIR_TEXT     or File.join($BASEDIR, 'text'))

# ENV['PATH'] = "/bin:/usr/bin:/usr/local/bin"

$metapages = {
  'MetaPages'   => '#metapages',
  'RecentPages' => '#recentpages',
  'AllPages'    => '#allpages',
  'OrphanedPages' => '#orphanedpages',
  'NotCreatedPages' => '#notcreatedpages',
  'PluginList' => '#pluginlist',
  'ReverseLinkList' => '#reverselinklist',
  'SearchPage' => '#search',
}

