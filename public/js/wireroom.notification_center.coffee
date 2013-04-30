
class window.WRNotificationCenter
  settings:
    disableNotification: false

  constructor: (@wireroom, @options) ->
    that = this
    ifSupport = (allowed) =>
      console.log "Notification is supported."
      # $("#window-notification").bind "change", (e) ->
      #   if e.target.value is "on"
      #     @enableNotification()
      #   else if e.target.value is "off"
      #     @disableNotification()
      @wireroom.socket.on "says", (message) =>
        console.log "notification", message
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


window.NotificationCenter =
  create: ->
    that = this

  enableNotification: (cb) ->
    return unless window.webkitNotifications
    that = this
    permission = window.webkitNotifications.checkPermission()
    unless permission is 0
      window.webkitNotifications.requestPermission ->
        that.settings.disableNotification = false
        cb() if $.isFunction(cb)
    else
      that.settings.disableNotification = false
      cb()  if $.isFunction(cb)
    false

