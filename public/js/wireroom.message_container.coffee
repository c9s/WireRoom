
class window.WireRoomMessageContainer
  constructor: (@wireroom,@container,@options) ->
    @wireroom.socket.on "says", (x) =>
      return if x.room != @options.room
      console.log "says", x
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
