
var MimeEmail = {
    parse: function(text) {
        var data = {  };
        var regs;
        if( regs = text.match( /"?(.*?)"?\s*<(.*?)>/ ) ) {
            data.name = regs[1];
            data.email = regs[2];
        }
        else if( regs = text.match( /([a-z.-]+)@/i ) ) {
            data.email = text;
            data.name = regs[1];
        }
        else {
            data.name = text;
        }
        return data;
    }
};
