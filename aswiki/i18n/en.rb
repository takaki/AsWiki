# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

module AsWiki
  module I18N
    def msg_edit;        'Edit'  end
    def msg_recentpages; 'RecentPages' end
    def msg_allpages   ; 'AllPages' end
    def msg_historypage; 'History' end
    def msg_diffpage   ; 'Diff' end
    def msg_rawpage    ; 'RawData' end
    def msg_toppage    ; 'Top' end
    def msg_helppage;    'HelpPage' end
    def msg_lastmodified; 'Last-Modified' end

    def msg_version; 'Ver.' end
    def msg_raw; 'raw' end
    def msg_diff; 'diff' end
    def msg_modified_time; 'Modified-Time' end
    def msg_diff_from_current; 'diff from current' end
    def msg_diff_from_previous; 'diff from previous' end

    def msg_ver_pre; 'Ver.' end
    def msg_ver_post; '' end

    def msg_list_item; 'Item' end
    def msg_list_add; 'add' end

    def msg_2chbbs_anonymous; 'Anonymous' end
    def msg_2chbbs_from; 'Name' end
    def msg_2chbbs_date; 'Date' end
    def msg_2chbbs_weekstr; %w[Sun Mon Tue Wed Thu Fri Sat] end
    def msg_2chbbs_write; 'Post' end
  end
end
