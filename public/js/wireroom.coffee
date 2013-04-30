$.getScript("/js/json2.js") if typeof(JSON) is "undefined"

String::toCapitalCase = -> @charAt(0).toUpperCase() + this.slice(1).toLowerCase()

NotificationCenter =
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

WindowTitle =
  markAsRead: () ->
    document.title = (''+document.title).replace(/^\(\d+\) /, '')
  addUnread:  (cnt) ->
    try
      match = (''+document.title).match(/^\((\d+)\) (.*)/)
      if match
        document.title = '('+(parseInt(match[1])+cnt)+') '+match[2]
      else
        document.title = '(' + cnt + ') ' + document.title
    catch e
      console.error(e)


jenkinsMessageTemplate = () ->
  div class: "jenkins message clearfix", ->
    span class: "column icon", ->
      span class: "icon icon-cogs", ->
    span class: "column author", -> "Jenkins"
    span class: "column job", ->
      a target: "_blank", href: @job.url, -> @job.name
    span class: "column build", ->
      a target: "_blank", href: @build.url, -> @job.number
    span class: "column phase #{ @phase.toLowerCase() }", -> @phase.toCapitalCase()
    span class: "column status #{ @status.toLowerCase() }", -> @status.toCapitalCase()

githubCommitTemplate = () ->
  div class: "github message clearfix", ->
    span class: "column icon", ->
      span class: "icon icon-github", ->
    span class: "column author", ->
      a href: "http://github.com/" + @pusher.name, target: "_blank", ->
        @pusher.name
    span class: "column action", -> "pushed to"
    span class: "column branch", -> @ref.replace("refs/heads/", "")
    span class: "column hash before", -> @before.substr(0,5)
    span class: "column", -> "to"
    span class: "column hash after",  -> @after.substr(0,5)
    span class: "column count",  -> @commits.length
    time class: "column time", -> prettyDate(@timestamp)
    # "compare" (compare link)
    # "created":false,
    # "deleted":false,
    # "forced":false,
    # "ref":"refs/heads/master",
    # "repository":
    # "pusher.name"

gitCommitTemplate = () ->
  div class: "git message clearfix", ->
    span class: "column icon", ->
      span class: "icon icon-github-sign", ->
    span class: "column author", -> @user
    span class: "column action", -> "pushed to"
    span class: "column branch", -> @ref
    span class: "column hash before", -> @before.substr(0,5)
    span class: "column", -> "to"
    span class: "column hash after",  -> @after.substr(0,5)
    span class: "column count",  -> @commits.length
    time class: "column time", -> prettyDate(@timestamp)

gitCommitDetailTemplate = ->
  div ->
    div class: "detail-content git", ->
      div class: "commits" ,->
        for commit in @commits
          div class: "commit", ->
            div class: "meta clearfix", ->
              span class: "column id", -> commit.id.substr(0,5)
              span class: "column author", -> commit.author.name + " <#{ commit.author.email }> "
            div class: "message", -> commit.message












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

class SideDetailPanel
  constructor: (@trigger, @options) ->
    @popover = $('<div/>').html(@options.content)
    @popover.css('width', 360)
    @popover.css('left', @trigger.offset().left - 370 )
    @popover.css('top', @trigger.offset().top - (@popover.height() / 2) )
    $(document.body).append(@popover)

class NotificationPanel
  constructor: (@wireroom, @panel, @options) ->
    template = ->
      div class: "notification-panel"
    @container = $(CoffeeKup.render(template,{}))
    @container.appendTo(@panel)

    # pretty date updater

    setInterval (=>
      @container.find('.message').each (i,e) ->
        t = $(this).data('timestamp')
        $(this).find('.time').html( prettyDate(t) ) if t
    ), 1000

    @wireroom.socket.on "notification.jenkins", (data) =>
      return if data.room != @options.room
      # create notification and append to the panel
      # handle git messages
      content = $(CoffeeKup.render(jenkinsMessageTemplate, data))
      content.prependTo(@container)
        .data('timestamp', data.timestamp)

    @wireroom.socket.on "notification.github", (data) =>
      return if data.room != @options.room
      # create notification and append to the panel
      # handle git messages
      commitContent = $(CoffeeKup.render(githubCommitTemplate, data))
      commitContent.prependTo(@container)
        .data('timestamp', data.timestamp)
        # commitDetailContent = $(CoffeeKup.render(gitCommitDetailTemplate, data))

    @wireroom.socket.on "notification.git", (data) =>
      return if data.room != @options.room
      # create notification and append to the panel
      # handle git messages
      commitContent = $(CoffeeKup.render(gitCommitTemplate, data))
      commitContent.prependTo(@container)
        .data('timestamp', data.timestamp)

      commitDetailContent = $(CoffeeKup.render(gitCommitDetailTemplate, data))

      # popover
      commitContent.popover
        title:   "Title"
        content: commitDetailContent
        position: "left"
        trigger: "hover"




      ###
      commitContent.popover({
        title: "Commit Details"
        content: () -> $('<div/>').html(commitDetailContent).html()
        trigger: "click"
        html: true
        delay:
          show: 200
          hide: 200
        container: "body"
        placement: "left"
      })
      ###

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
      messageContainer     = new WireRoomMessageContainer(self, messagePanelEl, { room: room })
      messageInput         = new WireRoomMessageInput(self, $panel, { room: room })
      sidePanel            = new WireRoomSidePanel(self, $panel, { room: room })
      gitNotificationPanel = new NotificationPanel(self, sidePanel.container, { room: room })

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

