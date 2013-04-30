
window.NotificationCenter =
  Settings:
    disableNotification: true
  create: ->
    that = this
    ifSupport = (allowed) ->
      $("#window-notification").bind "change", (e) ->
        if e.target.value is "on"
          that.enableNotification -> # callback
        else if e.target.value is "off"
          that.disableNotification -> # callback
      $("#notification-feature").show()  if allowed
    ifNotSupport = () ->
      $("#notification-feature").remove()

    NotificationChecker.check ifSupport, ifNotSupport

    $(document.body).bind "wireroom-message-says", (e, message_data, $m) ->
      return if new Date() - WireRoom.BOOT_TIME < 3000 or that.Settings.disableNotification or message_data.client is WireRoom.IDENTIFIER
      that.showNotification "/images/opmsg48x48.jpg", message_data.nickname + " says", message_data.html

  enableNotification: (cb) ->
    return unless window.webkitNotifications
    that = this
    permission = window.webkitNotifications.checkPermission()
    unless permission is 0
      window.webkitNotifications.requestPermission ->
        that.Settings.disableNotification = false
        cb() if $.isFunction(cb)
    else
      that.Settings.disableNotification = false
      cb()  if $.isFunction(cb)
    false

  disableNotification: (cb) ->
    @Settings.disableNotification = true
    cb()  if $.isFunction(cb)

  showNotification: (icon, title, text) ->
    return  unless window.webkitNotifications
    
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

