/**
 * vim:fdm=marker:
 */
if (typeof(JSON) == 'undefined') $.getScript("/js/json2.js");

var WireRoom;


String.prototype.toCapitalCase = function() {
    return this.charAt(0).toUpperCase() + this.slice(1).toLowerCase();
};


// fold git messages {{{
function fold_git_messages()
{
    fold_messages('.git.message',function(set) {
        // fold 5+ commits
        if( set.length < 3 )
            return;

        var $fold = $('<div/>').addClass('git-fold');
        var $text = $('<a/>').addClass('git-fold-text').html('many commits...').click(function() {
            $fold.find('.git.message').show();
            $(this).remove();
        });

        $(set[0]).before($fold);
        $(set).each(function(i,m) {
            $(m).hide();
            $fold.prepend(m);
        });
        $fold.prepend($text);
    });
}
//}}}

// fold messages {{{
function fold_messages(s,cb) 
{
    // find continuous commit divs to fold
    var messages = $('#content > ' + s);
    var m = messages.first();
    var sets = [];
    var set = [];
    while(m.get(0)) {
        var c = m.get(0);
        var n = m.next();
        if( n.is(s) ) {
            set.push(c);
            m = n;
        } else {
            set.push(c);
            sets.push(set);
            set = [];
            m = n.next();
        }
    }

    if(window.console)
        console.log( 'Folding commit messages' , sets);

    $(sets).each(function(i,set) {
        cb(set);

    });
    return sets;
}
//}}}

(function($){

    function repeat(str, i) {
        if (isNaN(i) || i <= 0) return "";
        return str + repeat(str, i-1);
    }

    // pad up to n Ys before X.
    function pad(x, n, y) {
        var zeros = repeat(y, n);
        return String(zeros + x).slice(-1 * n);
    }

    // build message element {{{
    function build_message(x) {
        var $m;
        x = _normalize_message_data(x);

        $m = $('<p class="message"></p>');

        $m.html( x.html );
        $m.find('a.oembed').oembed(null, {
            embedMethod: "replace",
            maxHeight: 400,
            vimeo: { autoplay: true, maxHeight: 400}     
        });

        var $img = Gravatar.getImage( x.avatar );
        var $avatar = $('<span/>').addClass('avatar');
        $avatar.append( $img );

        $m.prepend('<span class="nickname">' + x.nickname + '</span>');
        $m.prepend( $avatar );
        $m.prepend('<time>' + x.time + '</time>');
        return $m;
    }
    // }}}

    // build jenkins message {{{
    function build_jenkins_message(x)
    {
        x.time = _normalize_time( x.time );

        var $m = $('<p class="message jenkins"></p>');
        $m.data(x);

        var $avatar = $('<span/>').addClass('avatar');
        $avatar.append( $('<img/>').attr({ src: '/images/jenkins/logo.png' }) );

        var $job = $('<a/>').addClass('column job').attr({ target: '_blank', href: x.job.details.url }).html( x.job.name );
        var $build = $('<a/>').addClass('column build')
            .attr({ target: '_blank', href: x.build.details.url }).html( '#' + x.build.number );


        var $phase = $('<span/>').addClass('column phase ' + x.phase.toLowerCase() ).html( x.phase.toCapitalCase() );
        var $status = $('<span/>').addClass('column status ' + x.status.toLowerCase() ).html( x.status.toCapitalCase() );

        $m.prepend( $status );
        $m.prepend( $phase );
        $m.prepend( $build );
        $m.prepend( $job );

        $m.prepend('<span class="nickname">' + 'Jenkins' + '</span>');
        $m.prepend( $avatar );

        $m.prepend('<time>' + x.time + '</time>');
        return $m;
    }
    // }}}


    // build git message {{{
    function build_git_message(x)
    {
        function _trim_commit_message(text) {
            return text.replace( /^\s*/m ,'').replace( /\s*$/m , '' );
        }


        x.time = _normalize_time( x.time );

        var $m = $('<p class="message git"></p>');

        // save commit data, so that we can expand or fold them
        $m.data(x);

        // avatar => '',
        var $img = $('<img/>').attr({ src: 'http://ostatic.com/files/images/icon_git_image_1.png' });
        var $avatar = $('<span/>').addClass('avatar');
        $avatar.append( $img );

        var $commits = $('<div/>').addClass('commits');

        var cgit = new CGit( 'http://cgit.corneltek.com' );
        var repo = x.repository.replace( /^\/.*\/git\/repositories\// , '' );
        var $repo   = $('<span/>').addClass('repository').html( cgit.getRepoLink(repo) );
        var $diff   = $('<span/>').addClass('diff').html( cgit.getDiffLink(repo,x.before,x.after) );
        var $ref = $('<span/>').addClass('ref').text( x.ref );

        var $brief  = $('<span/>').addClass('brief').html($('<pre/>').text( 
                (function(m) { 
                    m = _trim_commit_message( m );
                    var ms = m.split( /\s*\n+\s*/ );
                    return ms[0] + ( ms.length > 1 ? '...' : '' ) ;
                })( x.commits[0].message )
            ));

        $(x.commits).each(function(i,commit) {
            var $commit = $('<div/>').addClass('commit');
            var $msg    = $('<span/>').addClass('message').html( $('<pre/>').text( _trim_commit_message( commit.message ) ) );
            // var $msg    = $('<span/>').addClass('message').text( commit.message  );
            var $name = $('<span/>').addClass('author').text( commit.author.name );
            var $email = $('<span/>').addClass('email').text( commit.author.email );
            var $id    = $('<span/>').addClass('id').text( commit.id.substr(0,6) );

            $commit.prepend( $msg );
            $commit.prepend( $name );
            $commit.prepend( $id );
            $commits.prepend( $commit );
        });

        var $toggle = $('<a/>').addClass('more').attr({  }).html( x.commits.length + ' commits' ).click(function() {
            $commits.toggle();
        });

        $commits.hide();
        $m.prepend( $commits );
        $m.prepend( $diff );
        $m.prepend( $toggle );
        $m.prepend( $brief );
        $m.prepend( $ref );
        $m.prepend( $repo );
        $m.prepend('<span class="nickname">Git</span>');
        $m.prepend( $avatar );
        $m.prepend('<time>' + x.time + '</time>');
        return $m;
    }
    // }}}

    // build action message {{{
    function build_action_message(x) {
        var $m;
        x = _normalize_message_data(x);

        var $img = Gravatar.getImage( x.avatar );
        var $avatar = $('<span/>').addClass('avatar');
        $avatar.append( $img );
        
        if( x.verb == "joined" || x.verb == "leaved" )
            return $m;

        $m = $('<p class="message action"></p>');
        $m.text(x.verb + (x.target ? (' '+x.target) : ''));
        $m.prepend('<span class="nickname">' + x.nickname + '</span>');
        $m.prepend( $avatar );
        $m.prepend('<time>' + x.time + '</time>');
        return $m;
    }
    // }}}

    // append message {{{
    function append_message($m) {
        var sha1 = CybozuLabs.SHA1.calc($m.html());
        if ($(".message[sha1=" + sha1 + "]").size() > 0) {
            return false;
        }

        $m.attr('sha1', sha1);
        $m.prependTo('#content');
        return true
    }
    // }}}

    function current_time(t) {
        var t2;

        if (!t) t = new Date();
        if (!t.getHours) {
            t2 = new Date();
            t2.setTime(t);
            t = t2;
        }
        return pad(t.getHours(), 2, 0) + ':' + pad(t.getMinutes(), 2, 0);
    }

    function _normalize_time(t)
    {
        if (!t) {
            return current_time();
        }
        else if (t.toString().match(/^\d+$/)) {
            return current_time( parseInt(t) * 1000 );
        }
    }

    function _normalize_message_data(x) {
        if (!x.nickname) x.nickname = "Someone";
        x.unixtime = x.time; // save unixtime
        x.time = _normalize_time( x.time );
        return x;
    }

    /**
     * get userinfo
     *
     * @return hash
     */
    function userinfo()
    {
        // get nickname value
        var n = $("#nickname").val();
        var info = MimeEmail.parse(n);
        var avatar = $('#avatar').val() || info.email;
        return {
            name: info.name,
            avatar: avatar,
            email: info.email
        };
    }

    /**
     * get or save a new nickname
     */
    function nickname(new_nickname) {
        var n;

        if (new_nickname) {
            n = $("#nickname").val();

            $("#nickname").attr("old-value", n).val(new_nickname);

            var info = MimeEmail.parse( new_nickname );
            return info.name;
        }
        n = $("#nickname").val();

        var info = MimeEmail.parse( n );
        return info.name;
    }


    function createHPipe(args) {
        var timer_update;
        var hpipe = window.hpipe = new Hippie.Pipe();
        hpipe.args = args; // channel name

        var status = $('#connection-status .status');
        $(hpipe)
            .bind("ready", function () {
                if (new Date() - WireRoom.BOOT_TIME < 3000) {
                    $(document.body).trigger("wireroom-joined");
                }
                if( window.console )
                    console.log(new Date,'wireroom: ready');

                var ping;
                ping = function() {
                    if( window.console )
                        console.log('wireroom: ping');
                    hpipe.send({
                        client: WireRoom.IDENTIFIER, 
                        type: 'ping',
                    });
                    setTimeout(ping, 1000 * 30 ); // per 30 seconds
                };
                ping();
            })
            .bind("connected", function () {
                status.addClass("connected").text("Connected");
                if(timer_update) clearTimeout(timer_update);
            })
            .bind("disconnected", function() {
                if( window.console )
                    console.log(new Date,'hpipe: server disconnected');
                status.removeClass("connected").text("Server disconnected. ");
            })
            .bind("reconnecting", function(e, data) {
                var retry = new Date(new Date().getTime()+data.after*1000);
                var try_now = $('<span/>').text("Try now").click(data.try_now);
                var timer = $('<span/>');
                var do_timer_update = function() {
                    timer.text( Math.ceil((retry - new Date())/1000) + "s. " )
                    timer_update = window.setTimeout( do_timer_update, 1000);
                };
                if( window.console )
                    console.log(new Date,'hpipe: reconnecting..');
                status.text("Server disconnected.  retry in ").append(timer).append(try_now);
                do_timer_update();
            })
            .bind("message.says", function (e, data) {
                var m = build_message(data);
                if (m && append_message(m)) {
                    $(document.body).trigger("wireroom-message-says", [data, m]);

                    // skip unread if we focus in textarea.
                    if( $('#message_body').is(':focus') )
                        return;
                    WindowTitle.addUnread();
                }
            })
            .bind("message.action", function (e, data) {
                var m = build_action_message(data);
                if(m)
                    append_message(m);
            });
        return hpipe;
    };


    WireRoom = {
        // NEVER-ish CHANGE THESE CAPITALZIE VALUES
        BOOT_TIME: new Date(),
        IDENTIFIER: CybozuLabs.SHA1.calc(Math.random().toString() + new Date().getTime()),

        HPipe: null,
        Settings: {  },

        init: function(args) {
            // TODO: load settings from cookie



            var ua = navigator.userAgent;
            var isMobile = !! ua.match( /iphone|android|ipod|blackberry/i );
            if( ! isMobile ) {
                // load Sidebar and Sidebar plugins
                WireRoom.View.Sidebar.init( $(document.body) );
            }
            this.addPlugin( WireRoom.Plugins.UserList );
            this.addPlugin( WireRoom.Plugins.ConnectionStatus );
            this.addPlugin( WireRoom.Plugins.Html5Notification );
            this.addPlugin( WireRoom.Plugins.Notification );
            this.addPlugin( WireRoom.Plugins.WindowTitle );


            $(this).trigger('wr-plugin-ui');

            var hpipe = createHPipe('arena');

            // init message form
            $("#message_form").bind("submit", function(e) {
                var matched, b = $("input[name=message_body]").val();
                e.preventDefault();
                if (b.match(/^\s*$/)) return false;

                // nickname rename command. (/nick NewNick)
                if (matched = b.match(/^\/nick\s+([\s\S]+)$/)) {
                    var old_nickname = nickname();
                    nickname(matched[1]);
                    $.cookie("wireroom_nickname", nickname(), { path: '/', expires: 365 });
                    $(document.body).trigger("wireroom-nickname-changed", [ old_nickname ]);
                }
                else {
                    var info = userinfo();
                    hpipe.send({
                        client: WireRoom.IDENTIFIER, 
                        type: "says", 
                        text:  b, 
                        nickname: info.name,
                        avatar: info.avatar,
                        email: info.email
                    });
                }

                $(this).find("input[name=message_body]").val("");
                return false;
            });
            hpipe.init();
            this.HPipe = hpipe;

            $(this).trigger('wr-plugin-init');
        },

        addPlugin: function(plugin) {
            plugin.create(this);
        },

        // View stash
        View: {

        },
        Plugins: {

        }
    };

    $(document.body).ready(function() {
        $('#option_panel').hide();
        $('#option_button').click(function() {
            $('#option_panel').toggle();
            return false;
        });

        // fold git commits every 10 minutes
        /*
        setInterval( function() { 
            fold_git_messages();
        } , 1000 * 60 * 10 );
        */
    });

    window.WireRoom = WireRoom;

    // initialize WireRoom
    $(function() {
        var n;

        $("#nickname").bind("change", function(e) {
            var old_nickname = $(this).attr("old-value");
            $("input[name=message_body]").focus();

            $.cookie("wireroom_nickname", $('#nickname').val() , { path: '/', expires: 365 });
            $(document.body).trigger("wireroom-nickname-changed", [ old_nickname ]);
            return false;
        });


        $('#emoticons').bind('change', function(e) {
            var emoticon = $(this).val();
            var text = $('#message_body').val();
            $('#message_body').val( text + ' ' + emoticon );

            $(this).find('option:first').attr('selected','true');
        });


        $('#avatar').bind('change', function(e) {
            // save avatar
            $.cookie('wireroom_avatar', $(this).val() , { path: '/', expires: 365 });
            // xxx: trigger avatar change.
        });
        var avatar;
        if( avatar = $.cookie('wireroom_avatar') ) {
            $('#avatar').val(avatar);
        }




        if (n = $.cookie("wireroom_nickname")) {
            nickname(n);
            $("#nickname").attr("old-value", n);
        }

        /*
        else if (n = $.cookie("wireroom_openid")) {
            nickname(n);
            $("#nickname").attr("old-value", n);
        }
        */
        WireRoom.init();

        // Custom Logics
        $(document.body)
            .bind("wireroom-joined", function() {
                var info = userinfo();
                WireRoom.HPipe.send({
                    type:"action", 
                    nickname: info.name, 
                    avatar: info.avatar,
                    verb:"joined"
                });
            })
            .bind("wireroom-nickname-changed", function(e, old_nickname) {
                var info = userinfo();
                WireRoom.HPipe.send({
                    type:"action", 
                    nickname: old_nickname, 
                    verb:'renamed to', 
                    avatar: info.avatar,
                    target: nickname()
                });
            });

        $(window).bind("unload", function() {
            var info = userinfo();
            WireRoom.HPipe.send({
                type: "action", 
                nickname: info.name,
                avatar: info.avatar,
                verb: "leaved"
            });
        });

        $("input[name=message_body]").focus();
    });

}(jQuery));
