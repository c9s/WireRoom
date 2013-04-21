
window.Gravatar =
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
