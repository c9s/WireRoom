
var WindowTitle = { 
    markAsRead: function() {
        document.title = (''+document.title).replace(/^\(\d+\) /, '');
    },
    addUnread: function() { 
        try {
            var title_match = (''+document.title).match(/^\((\d+)\) (.*)/);
            if( title_match )
                document.title = '('+(parseInt(title_match[1])+1)+') '+title_match[2];
            else
                document.title = '(1) ' + document.title;
        } catch(e) { }
    }
};
