$.getScript("/js/json2.js") if typeof(JSON) is "undefined"

class WireRoomSidePanel

  ###
  # @panel the main tab panel
  ###
  constructor: (@wireroom, @panel, @options) ->
    template = ->
      div class: "side-panel", ->
        div class: "handle", ->
    @container = $(CoffeeKup.render(template,{}))
    @panel.append @container
    @container.find('.handle').click (e) =>
      @container.toggleClass('show')


class GitNotificationPanel
  constructor: (@wireroom, @panel, @options) ->
    template = ->
      div class: "notification-panel"
    @container = $(CoffeeKup.render(template,{}))
    @container.appendTo(@panel)
    @wireroom.socket.on "notification.git", (data) =>
      return if data.room != @options.room
      # create notification and append to the panel
      # handle git messages

      commitTemplate = (payload) ->
        div class: "git", ->
          span class: "author", -> payload.user
          span class: "action", -> "push"
          span class: "before", -> payload.before
          span class: "after",  -> payload.after
          span class: "count",  -> payload.commits.length
      commitContent = $(CoffeeKup.render(commitTemplate, data))
      ###
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
      ###


class WireRoomConnectionStatus

  ###
  # @el the connection status element
  ###
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

class WireRoomChannelSearchInput
  constructor: (@wireroom, @form) ->
    self = this
    @searchInput = @form.find('input')
    @form.submit (e) ->
      room = self.searchInput.val()
      self.wireroom.joinChannel room
      return false

class WireRoomMessageInput
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
      @nicknameInput.val(n)

    @nicknameInput.change (e) ->
      # save nickname
      $.cookie("wireroom_nickname", $(@).val() , { path: '/', expires: 365 })

    self = this

    @wireroom.socket.on "connect",    => @enable()
    @wireroom.socket.on "disconnect", => @disable()

    @messageForm.submit =>
      message = @getMessage()
      nickname = @getNickname()
      @wireroom.socket.emit "publish",
        "nickname": nickname
        "message": message
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

    console.info "Wireroom Started."

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


    @plugins.status        = new WireRoomConnectionStatus(this, $('#connectionStatus') )
    @plugins.channelSearch = new WireRoomChannelSearchInput(this,$('#channelSearch'))

    @hasLogs = false


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
      console.info "socket.io connected."
      @joinChannel(room) for room in self.rooms

      # if we don't have logs, we should ask backlog
      # XXX: see if we can get backlogs from a snapshot?
      # return if @socket.hasLogs
      # @socket.emit("backlog",{room: room, limit: 10})
      # # we've asked backlogs
      # @socket.hasLogs = true

    @socket.on "disconnect", => console.warn "socket.io disconnected."

  joinChannel: (room) ->
    self = this

    # create a new tab for the channel
    @tabs.addTab room, room, ($panel) =>
      # create new message panel
      messagePanelEl   = $('<div/>')
      messagePanelEl.addClass('message-container').appendTo($panel)
      messageContainer = new WireRoomMessageContainer(self, messagePanelEl, { room: room })
      messageInput     = new WireRoomMessageInput(self, $panel, { room: room })
      sidePanel        = new WireRoomSidePanel(self, $panel, { room: room })

      gitNotificationPanel = new GitNotificationPanel(self, sidePanel.container, { room: room })

      @socket.emit "join",
        room: room
        ident: self.Identifier
        nickname: messageInput.getNickname()
      @socket.emit "backlog",{room: room, limit: 10}

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

