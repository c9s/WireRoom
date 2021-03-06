$.getScript("/js/json2.js") if typeof(JSON) is "undefined"

String::toCapitalCase = -> @charAt(0).toUpperCase() + @slice(1).toLowerCase()

class WRSidePanel
  ###
  # @panel the main tab panel
  ###
  constructor: (@wireroom, @panel, @options) ->
    @container = $(CoffeeKup.render(sidePanelTemplate,{}))
    @panel.append @container
    @container.find('.handle').click (e) =>
      @container.toggleClass('show')

class SideDetailPanel
  constructor: (@trigger, @options) ->
    @popover = $('<div/>').html(@options.content)
    @popover.css('width', 360)
    @popover.css('left', @trigger.offset().left - 370 )
    @popover.css('top', @trigger.offset().top - (@popover.height() / 2) )
    $(document.body).append(@popover)

class WRMessageInput
  constructor: (@wireroom, @panel, @options) ->
    templateContent = """
      <div class="input-panel clearfix">
        <form method="post" class="message-form" onsubmit="return false;">
            <div class="nickname-column">
                <div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">
                    <input class="nickname-input ui-input-text" type="text" name="" value="Someone">
                </div>
            </div>

            <div class="message-column">
                <div class="ui-input-text ui-shadow-inset ui-corner-all ui-btn-shadow ui-body-c">
                    <input class="message-input ui-input-text" type="text" name="message_body" value="">
                  </div>
            </div>

            <div class="submit-button">
                <button style="margin: 0px" type="submit" class="ui-btn ui-btn-corner-all ui-shadow ui-btn-up-c">
                    <span class="ui-btn-inner">
                        <span class="ui-btn-text">Send</span>
                    </span>
                </button>
            </div>
        </form>
      </div>
    """
    @container = $(templateContent)
    @panel.prepend(@container)

    @messageForm  = @container.find(".message-form")
    @messageInput = @container.find(".message-input")
    @nicknameInput = @container.find(".nickname-input")

    # load nickname from cookie
    if n = $.cookie("wireroom_nickname")
      @nickname = n
      @nicknameInput.val(@nickname)
    else
      @nickname = "Someone"
      @nicknameInput.val(@nickname)

    self = this

    @nicknameInput.change (e) ->
      self.origNickname = self.nickname
      self.nickname = $(this).val()
      $.cookie("wireroom_nickname", self.nickname , { path: '/', expires: 365 })
      # TODO: send nickname change event
      self.wireroom.socket.emit "action",
        "nickname": self.origNickname
        "verb":   "renamed to"
        "target": self.nickname
        "ident": self.wireroom.Identifier
        "room": self.options.room


    @wireroom.socket.on "connect",    => @enable()
    @wireroom.socket.on "disconnect", => @disable()

    @messageForm.submit =>
      message = @getMessage()
      nickname = @getNickname()
      return unless message
      return unless nickname
      @wireroom.socket.emit "publish",
        "nickname": nickname
        "message": message
        "ident": @wireroom.Identifier
        "room": @options.room
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
    @rooms = @options.rooms or ["Hall"]
    @tabs = new UITab($('#channelTabs'))

    # XXX: we may use navigator.onLine status to reconnect,
    #      but we need to disable reconnect flag.
    #
    # socket namespace
    @socket = socket = io.connect(null,{
      "reconnect": true
      "reconnection delay": 500
      "max reconnection attempts": 10
    })


    @plugins.status        = new WRConnectionStatus(this, $('#connectionStatus') )
    @plugins.channelSearch = new WRChannelSearchInput(this,$('#channelSearch'))

    # The unload event is sent to the window element when the user navigates
    # away from the page. This could mean one of many things. 
    # 1. The user could have clicked on a link to leave the page, or typed in a
    #    new URL in the address bar. 
    # 2. The forward and back buttons will trigger the event. 
    # 3. Closing the browser window will cause the event to be triggered. 
    # 4. Even a page reload will first create an unload event.
    $(window).bind "unload", () =>
      @leaveChannel(room) for room in self.rooms

    # a channel join event.
    @socket.on "join", (data) => console.log "join",data

    # a channel leaving event.
    @socket.on "leave", (data) => console.log "leave",data

    @socket.on "connect", =>
      @joinChannel(room) for room in self.rooms
    @socket.on "disconnect", => console.warn "socket.io disconnected."

    notificationCenter = new WRNotificationCenter(self)

  _joined: {}

  joinChannel: (room) ->
    self = this
    return if @_joined[ room ]
    @_joined[ room ] = true


    # create a new tab for the channel
    @tabs.addTab room, room, ($panel) =>
      # create new message panel
      messagePanelEl   = $('<div/>')
      messagePanelEl.addClass('message-container').appendTo($panel)
      messageContainer     = new WireRoomMessageContainer(self, messagePanelEl, { room: room })
      messageInput         = new WRMessageInput(self, $panel, { room: room })
      sidePanel            = new WRSidePanel(self, $panel, { room: room })
      notificationPanel    = new WRNotificationPanel(self, sidePanel.container, { room: room })

      @socket.emit "join",
        room: room
        ident: self.Identifier
        nickname: messageInput.getNickname()
      @socket.emit "backlog",{type: "says", room: room, limit: 200}
      @socket.emit "backlog",{type: "notification.git", room: room, limit: 5}
      @socket.emit "backlog",{type: "notification.github", room: room, limit: 5}
      @socket.emit "backlog",{type: "notification.jenkins", room: room, limit: 5}
      @socket.emit "backlog",{type: "notification.travis-ci", room: room, limit: 5}

  leaveChannel: (channelName) ->
    self = this
    @socket.emit "leave", {
      roomt: channelName
      ident: self.Identifier
      nickname: messageInput.getNickname()
    }

u.ready ->
  wireroom = new WireRoom({})
  onUpdateReady = () ->
    console.log('cache update ready.')
  window.applicationCache.addEventListener('updateready', onUpdateReady)
  if window.applicationCache.status is window.applicationCache.UPDATEREADY
    onUpdateReady()

