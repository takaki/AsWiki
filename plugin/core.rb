require 'obaq/htmlgen'
require 'obaq/htmlparser'

require 'wwiki/plugin'
require 'wwiki/util'

module WWiki
  class RecentPagesPlugin < Plugin
    Name = 'recentpages'
    include WWiki::Util
    def onview(line, b, e, av)
      count = (av[1] || 100 ).to_i
      data = {:data =>
	$repository.attrlist.sort{|a,b| b[1] <=> a[1]}.map{
	  |l| wikilink(l[0]) + " " + l[1].to_s}
      }
      @view = load_template.expand(data).to_s
    end
  end
  class AllPagesPlugin < Plugin
    Name = 'allpages'
    include WWiki::Util
    def onview(line, b, e, av)
      data = {:data => $repository.namelist.sort.collect{|f| wikilink(f)}}
      @view = load_template.expand(data).to_s
    end
  end
end


=begin
    return ["<ul>\n", 
      @repository.recentlist.select{|n| 
	! isspecialpage(n)}[0..count].map{|n| listitem(n, 'timestamp')},
      "</ul>\n"]
  end


module CoreUtil
  include PageRef
  def listitem(item, extra=false)
    ei = ''
    case extra
    when 'escape'
      ei = ' ' + Tiki.escape(item)
    when 'timestamp'
      ei = ' ' + @repository.lastmodified(item)
    end
    return @cgi.li{"#{filehref(item)}#{ei}"} +"\n"
  end
end

class TikiOrphanedPagesPlugin < TikiPlugin
  Name = 'orphanedpages'
  Description = _("#orphanedpages: Orphaned Pages.")
  include PageRef
  include CoreUtil
  @@run = false
  def onview(session, line, b, e)
    # return nil if (!(line[0] =~ /^#\s*orphanedpages\s*$/));
    return nil if @@run == true
    checked = ['TikiHelp'];
    @@run = true
    markandsweep($TOPPAGENAME, checked)
    @@run = false
    p = @repository.list - checked;
    return ["<ol>", p.select{|n| !Tiki.isspecialpage(n)}.map{|f| 
	listitem(f,'escape')},"</ol>"]
  end
  private
  def markandsweep(pagename, checked)
    if pagename.empty? then  return  end
    checked << pagename
    @repository.exists(pagename) ? 
    p = PageFormatter.new(pagename, @repository.load(pagename),
			  @sys.plugins, @sys.session): return
    (p.wikilinks.map{|f|
       expandwikiname(pagename, f)}.uniq - checked).each {|l|
      markandsweep(l, checked) }
    return 
  end
end

class TikiCommentPlugin < TikiPlugin
  Name = 'comment'
  Description = '#comment {ascent|decent}: comment plugin '
  include TikiHtmlUtil
  def onview(session, line, b, e)
    return nil if (!(line[0] =~ /^#\s*comment\s*(ascent|decent)?$/));
    order = $1 ? ($1 == ascent) : $comment_order 
    h = prepare_hiddens(session, b, e);
    h.update({'proc'=>'savecomment', 'cmdline'=>line[0].to_s.chomp,
	       'order'=> order});
    return [html_form('post', "#{$CGIURL}"),
      'Name:', html_inputtext('who', '', 6), 
      'Comment:', html_textarea('comment', '', 45, 1), 
      html_submitbutton("Comment"),
      store_hiddens(h),
      '</form>'];
  end
  def onpost(session)
    restore_persistence(session, ['proc', 'comment', 'who', 'cmdline','order']);
    return if (@proc != 'savecomment');
    @r = @repository.load(@sys.page);
    s = comment_form(@who, @comment)
    @repository.store_comment(@sys.page, s);
    if @order.to_i == 0
      @r[@bline-1] = sprintf("%s\n%s .\n", @cmdline, s)
    else
      @r[@bline-1] = sprintf("%s .\n%s\n", s, @cmdline)
    end
    return SavePage.new(@sys, @sys.page, @r, false, false);
  end
  def comment_form(user, content)
    user = user == '' ? '  ' : ' [[' + user.to_s + ']] ';
    return toCharSet(Tiki.getTimenow(@sys.now) + user + content.to_s);
  end
end

class TikiFindPlugin < TikiPlugin
  Name = 'find'
  Description = _("#find {true|fale} {true|fale} {true|fale} word: regexp ignorecase title word: Find Pages;")
  include CoreUtil
  def onview(session, line, b, e)
    tf ="true|false"
    return nil if ! (line[0] =~/^#\s*find\s+(#{tf})\s+(#{tf})\s+(#{tf})\s+(.*)\s*$/)
    regexp, ignorecase, title = $~[1,3].map {|s| s == 'true'}
    word = $~[4]
    begin
      pat_word = getpattern(word, regexp, ignorecase);
    rescue RegexpError
      raise TikiRegexpError, $!.message
    end
    fl = ['<h2>' + CGI::escapeHTML(word) + "</h2>\n"];
    dirlist = @repository.list
    found = dirlist.select{|f|
      if title 
	f.index(pat_word) != nil
      else
	@repository.load(f).find { |line| (line.index(pat_word) != nil)}
      end
    }.map{|f| listitem(f)}
    fl << "<ol>\n" << found << "</ol>\n" <<
      "#{found.size} page(s) found out of #{dirlist.size} pages searched"
    return fl
  end
  private
  def getpattern(word, regexp, ignorecase)
    return (regexp || ignorecase)  ? 
    Regexp::compile(word, casesw(ignorecase)) : word
  end
  def casesw(ignorecase) 
    return ignorecase ? Regexp::IGNORECASE : ! Regexp::IGNORECASE ;
  end
end

class TikiReferersPlugin < TikiPlugin
  Name =  'referers'
  Description = "#referers: Referers; "
  include PageRef
  include RefererUtil
  def onview(session, line, b, e)
    return nil if ! (line[0] =~ /^#\s*referers\s+(.+)\s*$/)
    name = $1
    c = [];  u = [];  
    l = @attrmanager.referers(name)
    total = 0;
    m = l.sort{|b,a| (a.mtime == b.mtime ) ? a.count <=> b.count : a.mtime <=> b.mtime}
    l.each { |f| total = total + f.count }
    maxval = l.map{ |f| f.count}.max
    minval = l.map{ |f| f.count}.min
    p = readreferers;
    num = l.length;
    exists = {};
    refcount = 0;
    m.each do |r| 
      count = r.count;
      referer = r.referer;
      catch(:tag) do 
	p.each do |pat, kind, key| 
	  if (pat =~ referer) then
	    content = construct_referer_link(pat, referer, kind, key);
	    next if content == nil;
	    refcount += count;
	    next if (exists.has_key?(content));
	    exists[content] = true;
	    c << sprintf("<li>%s %s (%s)</li>\n", 
			 wikihref(content[2..-3]),
			 ($REFERER_SHOW_COUNTER ? "[#{count}]" : 
			  referer_weight(r.count, maxval, minval, num, total)),
			 Tiki.getTimenow(Time.at(r.mtime)))
	    throw(:tag)
	  end
	end
        u << sprintf("<li>%s %s (%s)</li>\n",
		     ahref(r.referer, CGI::escapeHTML(r.referer)),
		     ($REFERER_SHOW_COUNTER ? "[#{count}]" : 
		      referer_weight(r.count, maxval, minval, num, total)), 
		     Tiki.getTimenow(Time.at(r.mtime)))
      end
    end
    if (c == []) then
      c = $SAVEREFERER ? ['No registered referer exists'] : ['Referer not available on this server'] ;
    else
      refhosts     = c.size;
      unknownhosts = u.size;
      c = [ "<ul>\n", c, "</ul>\n"]
      c << "The number of registered referers is #{refhosts}. (above)" # if (refhosts > 0);
      c += [ "<ul>\n", u, "</ul>\n"] if ($REFERER_SHOW_UNREGISTERED);
      c << "The number of unregistered referers is #{unknownhosts}. (hidden)" # if (unknownhosts > 0);
    end
    return c
  end
  private
  def referer_weight(count, mx, mi, num, total)
    @ref_weight = {0 => 'rare', 1 => 'low', 2 => 'medium', 3 => 'high',  4 => 'heavy', 5 => 'dense'} if (@ref_weight == nil);
    return '-' if (mi > mx);
    return '-' if (mx - mi < num);
    return '-' if (total == 0);
    percent = (count * 100) / total / 10 /  2; 
    return sprintf("%s", @ref_weight[percent]);
  end
end

class TikiFindformPlugin < TikiPlugin
  Name = 'findform'
  Description = '#findform: comment plugin '
  include TikiHtmlUtil
  def onviewx(session, line, b, e, av)
    h = prepare_hiddens(session, b, e);
    return @cgi.form('post', "#{$CGIURL}",nil){
      [@cgi.text_field('p'), @cgi.br,
	_('Word Search:'), @cgi.submit('Search','c'), @cgi.br,
	_('Title Search:'), @cgi.submit('TitleSearch','c'), @cgi.br,
	_('Word Search(Regexp):'), @cgi.submit('SearchRegexp','c'), 
	@cgi.br,
	_('Title Search(Regexp):'), @cgi.submit('TitleSearchRegexp','c'),
	@cgi.br,
	_('Strict case:'), @cgi.checkbox('scase','yes',true)].join("\n")
    }
 end
end
=end
