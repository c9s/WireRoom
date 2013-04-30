window.WindowTitle =
  markAsRead: -> document.title = ( '' + document.title).replace(/^\(\d+\) /, '' )
  addUnread:  (cnt) ->
    try
      match = ( '' + document.title).match(/^\((\d+)\) (.*)/)
      if match
        document.title = '('+(parseInt(match[1])+cnt)+') '+match[2]
      else
        document.title = '(' + cnt + ') ' + document.title
    catch e
      console.error(e)

