class window.WRNotificationPanel
  constructor: (@wireroom, @container, @options) ->
    @panel = $(CoffeeKup.render(notificationPanelTemplate,{}))
    @panel.appendTo(@container)

    @messageContainer = @container.find('.notification-panel')

    # pretty date updater

    setInterval (=>
      @messageContainer.find('.message').each (i,e) ->
        t = $(this).data('timestamp')
        $(this).find('.time').html( prettyDate(t) ) if t
    ), 1000

    hookNotification = (type, templateHandle) =>
      @wireroom.socket.on "notification." + type, (data) =>
        return if data.room != @options.room
        content = $(CoffeeKup.render(templateHandle, data))
        content.prependTo(@messageContainer).data('timestamp', data.timestamp)

    hookNotification "travis-ci", travisMessageTemplate
    hookNotification "jenkins", jenkinsMessageTemplate
    hookNotification "github", githubCommitTemplate

    # commitDetailContent = $(CoffeeKup.render(gitCommitDetailTemplate, data))

    @wireroom.socket.on "notification.git", (data) =>
      return if data.room != @options.room
      # create notification and append to the panel
      # handle git messages
      commitContent = $(CoffeeKup.render(gitCommitTemplate, data))
      commitContent.prependTo(@messageContainer).data('timestamp', data.timestamp)
      commitContent.popover
        title:   "Commit Detail"
        content: $(CoffeeKup.render(gitCommitDetailTemplate, data))
        position: "left"
        trigger: "hover"

