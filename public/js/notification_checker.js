var NotificationChecker = {
    check: function(supported_cb, unsupported_cb) {
        if (!window.webkitNotifications) {
            if ($.isFunction(unsupported_cb)) unsupported_cb();
            return false;
        }
        var allowed = false;
        var permission = window.webkitNotifications.checkPermission();

        if (permission != 0) {
            window.webkitNotifications.requestPermission(function() {
                allowed = true;
                // if ($.isFunction(cb)) cb();
            });
        }

        // permission == 0 , your browser supports notification, and is allowed.
        // permission != 0 , your browser supports notification, but is unallowed.
        if ($.isFunction(supported_cb)) 
            supported_cb(permission);    
        return allowed;
    }
};
