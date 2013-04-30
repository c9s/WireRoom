
class window.WRNotificationCenter
  settings:
    disableNotification: false

  constructor: (@wireroom, @options) ->
    ifSupport = (allowed) =>
      console.log "Notification is supported."
      # $("#window-notification").bind "change", (e) ->
      #   if e.target.value is "on"
      #     @enableNotification()
      #   else if e.target.value is "off"
      #     @disableNotification()
      @wireroom.socket.on "says", (message) =>
        return if new Date() - @wireroom.BootTime < 3000 or @settings.disableNotification or
          message.ident is @wireroom.Identifier
        @showNotification "/images/opmsg48x48.jpg", message.nickname + " says", message.message
    ifNotSupport = () ->
      # $("#notification-feature").remove()
    NotificationChecker.check ifSupport, ifNotSupport

  disableNotification: (cb) ->
    @settings.disableNotification = true
    cb()  if $.isFunction(cb)

  showNotification: (icon, title, text) ->
    return unless window.webkitNotifications
    
    # strip html tags
    text = text.replace(/<[^>]*>/, "")
    try
      if 0 is window.webkitNotifications.checkPermission()
        x = window.webkitNotifications.createNotification(icon, title, text)
        x.ondisplay = ->
          setTimeout (->
            x.cancel()
          ), 3000
        x.show()

  enableNotification: (cb) ->
    return unless window.webkitNotifications
    permission = window.webkitNotifications.checkPermission()
    unless permission is 0
      window.webkitNotifications.requestPermission =>
        @settings.disableNotification = false
        cb() if $.isFunction(cb)
    else
      @settings.disableNotification = false
      cb()  if $.isFunction(cb)
    false
