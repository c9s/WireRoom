class window.UITab
  tabPanels: { }

  constructor: (@el) ->
    self = this
    @ul = @el.find('ul')
    @ul.find('a').each (i,e) ->
      selector = $(this).attr('href')
      panel = self.el.find(selector)
      panel.addClass('tab-content')
      panel.hide()
      self.el.trigger('addtab', [panel])

  hidePanels: -> @el.find('.tab-content').hide()

  container: -> @el

  addTab: (tabId, label, cb) ->
    ul = @el.find('ul')
    li = $('<li/>')
    a = $('<a/>').html(label).attr({ href: '#' + tabId })
    a.addClass('ui-link')
    a.appendTo(li)
    li.appendTo(ul)

    panel = $('<div/>')
    panel.appendTo( @el ).addClass('tab-content')
    @tabPanels[ tabId ] = { handle: li, panel: panel, a: a }

    a.click (e) =>
      @hidePanels()
      panel.show()
      @el.trigger('activatetab',[panel])
      return false

    cb panel if cb

  removeTab: (tabId) ->
    o = @tabPanels[ tabId ]
    if o
      o.handle.remove()
      o.panel.remove()
      delete(@tabPanels[tabId])
