$.getScript("/js/json2.js") if typeof(JSON) is "undefined"

Utils = {}
Utils.current_time = (t) ->
  t = new Date() if not t
  if not t.getHours
    t2 = new Date()
    t2.setTime(t)
    t = t2
  return Utils.pad(t.getHours(), 2, 0) + ':' + Utils.pad(t.getMinutes(), 2, 0)

Utils.normalize_time = (t) ->
  return Utils.current_time() if not t
  return Utils.current_time(parseInt(t) * 1000) if t.toString().match(/^\d+$/)

Utils.pad = (x, n, y) ->
  zeros = Utils.repeat(y, n)
  return String(zeros + x).slice(-1 * n)

Utils.repeat = (str, i) ->
  return "" if isNaN(i) or i <= 0
  return str + Utils.repeat(str, i-1)

Gravatar =
  getImage: (text) ->
    src = undefined
    if not text
      src = "http://www.gravatar.com/avatar/" + $.md5('foo')
    else
      if text and text.match( /@/ )
        src = "http://www.gravatar.com/avatar/" + $.md5(text)
      else if text and text.match(/^https?:/)
        src = text
    img = $('<img/>').attr('src', src)
    img.attr('alt',text) if text
    return img

class WireRoomMessageContainer
  constructor: (@wireroom,@options) ->
    @container = $("#messageContainer")
    @wireroom.socket.on "message.says", (x) =>
      $m = @buildMessage(x)
      @container.prepend($m)

  buildMessage: (x) ->
    x = @normalize(x)
    $m = $('<p class="message"></p>')
    $m.text( x.message )

    # $m.find('a.oembed').oembed null,
    #   embedMethod: "replace",
    #   maxHeight: 400,
    #   vimeo:
    #     autoplay: true
    #     maxHeight: 400

    $img = Gravatar.getImage( x.avatar )
    $avatar = $('<span/>').addClass('avatar').append( $img )
    $m.prepend('<span class="nickname">' + x.nickname + '</span>')
      .prepend( $avatar )
      .prepend('<time>' + x.time + '</time>')
    return $m

  normalize: (x) ->
    x.nickname = "Someone" if not x.nickname
    x.time     = Utils.normalize_time( x.timestamp )
    return x


class WireRoomConnectionStatus
  constructor: (@wireroom,@el) ->
    @bind(@wireroom.socket)

  # bind with a socket
  bind: (s) ->
    s.on "connecting", () =>
      @el.text("Connecting...")
      @el.removeClass().addClass("connecting")

    s.on "connect", () =>
      @el.text("Connected.")
      @el.removeClass().addClass("connected")

    s.on "connect_failed", () =>
      @el.text("Connect failed.")
      @el.removeClass().addClass("connectFailed")

    s.on "disconnect", () =>
      @el.text("Disconnected.")
      @el.removeClass().addClass("disconnected")

    s.on "message", () =>

    s.on "reconnect", () =>
      @el.text("Reconnected.")
      @el.removeClass().addClass("reconnected")

    s.on "reconnecting", () =>
      @el.text("Reconnecting...")
      @el.removeClass().addClass("reconnecting")

    s.on "reconnect_failed", () =>
      @el.text("Reconnect failed.")
      @el.removeClass().addClass("reconnectFailed")

    u(window).on "offline", (e) =>
      # @el.text("Offline")
      console.warn("offline")

    u(window).on "online", (e) ->
      console.info("online")

class WireRoomMessageInput
  constructor: (@wireroom) ->
    @messageForm  = $("#messageForm")
    @messageInput = $("#messageInput")
    @nicknameInput = $("#nicknameInput")

    # load nickname from cookie
    if n = $.cookie("wireroom_nickname")
      @nicknameInput.val(n)

    @nicknameInput.change (e) ->
      # save nickname
      $.cookie("wireroom_nickname", $(@).val() , { path: '/', expires: 365 })

    self = this

    @wireroom.socket.on "connect", => @enable()
    @wireroom.socket.on "disconnect", => @disable()

    @messageForm.submit =>
      message = @getMessage()
      nickname = @getNickname()
      for room in @wireroom.rooms
        @wireroom.socket.emit("message.publish",{
          "nickname": nickname
          "message": message
          "room": room
        })
      # clear message
      @messageInput.val("").focus()
      return false

  enable: ->
    @messageInput.removeAttr('disabled')
    @nicknameInput.removeAttr('disabled')

  disable: ->
    @messageInput.attr "disabled", true
    @nicknameInput.attr "disabled", true

  getNickname: -> @nicknameInput.val()

  getMessage: -> @messageInput.val()

class WireRoom
  plugins: {}
  constructor: (@options) ->

    self = this

    @BootTime = new Date()
    @Identifier = CybozuLabs.SHA1.calc(Math.random().toString() + new Date().getTime())

    console.info "Wireroom Started."

    @rooms = @options.rooms or ["corneltek"]

    # XXX: we may use navigator.onLine status to reconnect,
    #      but we need to disable reconnect flag.
    @socket = socket = io.connect(null,{
      "reconnect": true
      "reconnection delay": 500
      "max reconnection attempts": 10
    })

    @plugins.status = new WireRoomConnectionStatus(this, $('#connectionStatus') )
    @plugins.messageInput = new WireRoomMessageInput(this)
    @plugins.messageContainer = new WireRoomMessageContainer(this)

    @hasLogs = false


    # The unload event is sent to the window element when the user navigates
    # away from the page. This could mean one of many things. 
    # 1. The user could have clicked on a link to leave the page, or typed in a
    #    new URL in the address bar. 
    # 2. The forward and back buttons will trigger the event. 
    # 3. Closing the browser window will cause the event to be triggered. 
    # 4. Even a page reload will first create an unload event.
    $(window).bind "unload", () =>
      @socket.emit "leave", {
        roomt: room
        ident: self.Identifier
        nickname: self.plugins.messageInput.getNickname()
      } for room in self.rooms

    @socket.on "join", (data) => console.log "join",data
    @socket.on "leave", (data) => console.log "leave",data

    @socket.on "connect", =>
      console.info "socket.io connected."
      @socket.emit("join",{
        room: room
        ident: self.Identifier
        nickname: self.plugins.messageInput.getNickname()
      }) for room in self.rooms

      # if we don't have logs, we should ask backlog
      # XXX: see if we can get backlogs from a snapshot?
      if not @socket.hasLogs
        @socket.emit("backlog",{room: room, limit: 10})
        # we've asked backlogs
        @socket.hasLogs = true

    @socket.on "disconnect", =>
      console.warn "socket.io disconnected."

u.ready ->
  wireroom = new WireRoom({})

  onUpdateReady = () ->
    console.log('cache update ready.')
  window.applicationCache.addEventListener('updateready', onUpdateReady)
  if window.applicationCache.status is window.applicationCache.UPDATEREADY
    onUpdateReady()

