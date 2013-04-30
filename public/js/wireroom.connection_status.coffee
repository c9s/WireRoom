
class window.WRConnectionStatus
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

