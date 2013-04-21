
WireRoom.View.Sidebar = {
    init: function(container) { 
        var s = $('<div/>');
        s.attr('id','sidebar');

        var f = $('<div/>').addClass('title');
        f.append( $('<a/>').attr({ id: 'opt-panel-btn' }).html('Options') );
        s.append(f);

        container.append(s);
        this.el = s;
    },
    getEl: function() {
        return this.el;
    }
};


WireRoom.Plugins.UserList = {
    create: function(w) {
        var that = this;
        $(w).bind('wr-plugin-ui', function() {
            var s = WireRoom.View.Sidebar.getEl();
            if(s)
                that.View.UserListPanel.init(s);
        });

        $(w).bind('wr-plugin-init',function() {
            var s = WireRoom.View.Sidebar.getEl();
            // get WireRoom instance and bind the
            // client_list event
            if(s) {
                $(WireRoom.HPipe).bind("message.client_list"  , function (e, data) {
                    if( data.clientlist ) {
                        that.refresh(data.clientlist);
                    }
                });
            }
        });
    },
    getPanel: function() {
        return this.View.UserListPanel.panel;
    },
    refresh: function(clients) {
        var that = this;
        var panel = this.getPanel();
        panel.ul.empty();
        $(clients).each(function(i, client) {
            panel.ul.append( $("<li></li>").text(client.nickname) );
        });
    },
    View: {
        UserListPanel: {
            init: function(container) { 
                var u = $('<div/>').attr('id','userlist');
                var ul = $('<ul/>');

                // title
                var t = $('<div/>').addClass('title').html('Contacts');
                this.panel = u;
                this.panel.ul = ul;
                u.append(t).append(ul);
                container.append(u);
            }
        }
    }
};


WireRoom.Plugins.ConnectionStatus = { 
    create: function(w) {
        var that = this;
        $(w).bind('wr-plugin-ui',function() {
            var s = WireRoom.View.Sidebar.getEl();
            if(s)
                that.View.StatusPanel.init(s);
        });
    },
    View: {
        StatusPanel: {
            init: function(container) { 
                var u = $('<div/>').attr('id','connection-status');
                var s = $('<div/>').addClass('status');
                u.append(s);
                container.append(u);
            }
        }
    }
};


WireRoom.Plugins.Notification = { 
    create: function(w) { 

        var JenkinsItemView = Backbone.View.extend({
            tagName: 'div',
            className: 'item jenkins-item',
            template: _.template($('#jenkins-item').html()),
            initialize: function(payload) {
                this.payload = payload;
            },
            render: function() {
                this.$el.addClass(this.payload.phase.toLowerCase() );
                this.$el.addClass(this.payload.status.toLowerCase() );
                this.$el.html(this.template(this.payload));
                return this;
            }
        });

        var CommitPreviewView = Backbone.View.extend({
            tagName: 'div',
            className: 'git-commits-preview',
            template: _.template($('#git-commits-preview').html()),
            initialize: function(payload) {
                this.payload = payload;
            },
            open: function() { 
            },
            close: function() { 
            
            },
            render: function() { 
                this.$el.html(this.template(this.payload));
                return this;
            }
        });

        var CommitItemView  = Backbone.View.extend({
            tagName: 'div',
            className: 'item git-commits-item',
            template: _.template($('#git-commits-item').html()),
            events: { 
                "mouseover"   : "openPreview",
                "mouseout"   : "closePreview"
            },
            initialize: function(x) {
                this.payload = x;
                // preprocess payload information
                this.payload.repository_name = x.repository.replace( /^.*?(\w+)(\.git)?$/ , "$1" );
            },
            render: function(data) {
                this.$el.html(this.template(this.payload));
                return this;
            },
            getPreview: function() {
                if(this.preview)
                    return this.preview;
                this.preview = new CommitPreviewView(this.payload);
                this.preview.render();
                this.preview.$el.hide();
                $(document.body).append( this.preview.el );
                return this.preview;
            },
            openPreview: function() { 
                var p = this.getPreview();

                // adjust position
                var windowWidth = $(window).width();
                var previewWidth = windowWidth * 0.4; // 40%
                if( previewWidth < 250 )
                    previewWidth = 250;

                var left = $('#sidebar').width();
                var top  = this.$el.position().top;

                if(top < 120)
                    top = 20;
                else
                    top -= 100;

                p.$el.css({
                    position: 'fixed',
                    right: (left + 10) + 'px',
                    top: top,
                    width: previewWidth
                });

                p.$el.fadeIn('fast',function() { 
                
                });
            },
            closePreview: function() { 
                var p = this.getPreview();
                if( this._t )
                    clearTimeout(this._t);
                this._t = setTimeout(function() { 
                    p.$el.fadeOut('fast',function() { });
                },100);
            }
        });


        var that = this;
        $(w).bind('wr-plugin-ui',function() {
            var s = WireRoom.View.Sidebar.getEl();
            if(s)
                that.View.NotificationPanel.init(s);
        });
        $(w).bind('wr-plugin-init',function() {
            var s = WireRoom.View.Sidebar.getEl();

            if(s) {
                var p = that.View.NotificationPanel.panel;
                $(WireRoom.HPipe).bind("message.jenkins.notification", function(e,data) {
                    /*
                    {
                        "name":"JobName",
                        "url":"JobUrl",
                        "build":{
                            "number":1,
                            "phase":"STARTED",
                            "status":"FAILED",
                            "url":"job/project/5",
                            "fullUrl":"http://ci.jenkins.org/job/project/5"
                            "parameters":{"branch":"master"}
                        }
                    }
                    */
                    var item = new JenkinsItemView(data);
                    p.prepend(item.render().el);
                });

                $(WireRoom.HPipe).bind("message.git", function(e,data) {
                    /*
                        data.after, data.before 
                        data.commits @array
                            { 
                                id: [commit ref string],
                                author: {
                                    name: [string],
                                    email: [string]
                                },
                                date: [string],
                                merge: [optional] { parent1 => [commit ref string] , parent2 => [commit ref string] }
                            }
                        data.user pushed by {user}
                        data.ref (branch name or tag name)
                        data.ref_type (reference type: 'heads', 'tags')
                        data.type = 'git'
                        data.new_head = [boolean]  ? is a new tag or new branch ?
                        data.is_delete = [boolean] ? is deleted ?
                        data.time = [time string]
                    */
                    var item = new CommitItemView(data);
                    p.prepend(item.render().el);
                });
            } else {

                $(WireRoom.HPipe).bind("message.jenkins.notification" , function(e,data) {
                    var m = build_jenkins_message(data);
                    if(m) {
                        append_message(m);
                    }
                });

                $(WireRoom.HPipe).bind("message.git", function(e,data) {
                    var m = build_git_message(data);
                    if(m) {
                        append_message(m);
                    }
                });
            }
        });
    },
    View: {
        NotificationPanel: { 
            init: function(container) {
                var u = $('<div/>').attr('id','notifications');
                var t = $('<div/>').addClass('title').html('Notifications');
                var panel = $('<div/>').addClass('panel');
                u.append(t);
                u.append(panel);
                this.panel = panel;
                container.append(u);
            }
        }
    }
};

WireRoom.Plugins.Html5Notification = {
    Settings:  {
        disable_notification: true
    },
    create: function() { 
        var that = this;
        this.checkNotification(
            function(allowed) {
                $("#window-notification").bind("change", function(e) {
                    if( e.target.value == "on" ) {
                        that.enableNotification(function() { /* callback */ });
                    }
                    else if( e.target.value == "off" ) {
                        that.disableNotification(function() { /* callback */ });
                    }
                });

                if (allowed)
                    $("#notification-feature").show();
            },
            function() {
                $("#notification-feature").remove();
            }
        );

        $(document.body).bind("wireroom-message-says", function(e, message_data, $m) {
            if (new Date() - WireRoom.BOOT_TIME < 3000
                || that.Settings.disable_notification
                || message_data.client == WireRoom.IDENTIFIER) 
                    return;

            that.showNotification(
                "/images/opmsg48x48.jpg",
                message_data.nickname + " says",
                message_data.html
            );
        });
    },
    checkNotification: function(supported_cb, unsupported_cb) {
        return NotificationChecker.check( supported_cb , unsupported_cb );
    },
    enableNotification: function(cb) {
        if (!window.webkitNotifications) return;
        var that = this;
        var permission = window.webkitNotifications.checkPermission();
        if (permission != 0) {
            window.webkitNotifications.requestPermission(function() {
                that.Settings.disable_notification = false;
                if ($.isFunction(cb)) cb();
            });
        }
        else {
            that.Settings.disable_notification = false;
            if ($.isFunction(cb)) cb();
        }

        return false;
    },
    disableNotification: function(cb) {
        this.Settings.disable_notification = true;
        if ($.isFunction(cb)) cb();
    },
    showNotification: function(icon, title, text) {
        if (!window.webkitNotifications) return;
        // strip html tags
        text = text.replace(/<[^>]*>/,''); 
        try {
            if (0 == window.webkitNotifications.checkPermission()) {
                x = window.webkitNotifications.createNotification(icon, title, text);
                x.ondisplay = function() {
                    setTimeout(function() {
                        x.cancel();
                    }, 3000);
                };
                x.show();
            }
        } catch(e) {}
    }
};

WireRoom.Plugins.WindowTitle = {
    create: function(w) {
        $('#message_body').focus(function() {
            WindowTitle.markAsRead();
        });
        $(window).focus(function() {
            WindowTitle.markAsRead();
        });
    }
};
