
class window.WireRoomMessageContainer
  constructor: (@wireroom,@container,@options) ->
    @wireroom.socket.on "action", (x) =>
      return if x.room != @options.room
      $m = @buildActionMessage(x)
      @container.prepend($m)

    @wireroom.socket.on "says", (x) =>
      return if x.room != @options.room
      $m = @buildMessage(x)
      @container.prepend($m)

  buildActionMessage: (x) ->
    x = @normalize(x)
    $m = $('<p class="action"></p>')
    $img = Gravatar.getImage( x.avatar )
    $avatar = $('<span/>').addClass('avatar').append( $img )
    $nick = $('<span class="nickname"/>').text( x.nickname )
    $verb = $('<span class="verb"/>').text( x.verb )
    $target = $('<span class="target"/>').text( x.target )
    $m.append('<time>' + x.time + '</time>')
      .append( $avatar )
      .append( $nick )
      .append( $verb )
      .append( $target )
    return $m

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

    $nick = $('<span class="nickname"/>').text( x.nickname + ":" )
    $m.prepend( $nick )
      .prepend( $avatar )
      .prepend('<time>' + x.time + '</time>')
    return $m

  normalize: (x) ->
    x.nickname = "Someone" if not x.nickname
    x.time     = Utils.normalize_time( x.timestamp )
    return x
