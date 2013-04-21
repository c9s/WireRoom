var CGit = function(url) {
    this.url = url;
};

CGit.prototype = {
    getRepoLink: function(repo) {
        var url = this.url + '/' + repo + '/';
        var $a = $('<a/>').attr({
            target: '_blank',
            href: url
        }).text( repo );
        return $a;
    },
    getDiffLink: function(repo,from,to) {
        var url = this.url + '/' + repo + '/diff/?id=' + to + '&id2=' + from;
        var $a = $('<a/>').attr({
            target: '_blank',
            href: url
        }).text('diff');
        return $a;
    }
};
