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

  hidePanels: -> @panels().hide()

  size: -> @panels().size()

  panels: -> @el.find('.tab-content')

  container: -> @el

  addTab: (tabId, label, cb) ->
    self = this

    ul = @el.find('ul')
    li = $('<li/>')
    a = $('<a/>').html(label).attr({ href: '#' + tabId }).data('tabId',tabId)
    a.addClass('ui-link')
    a.appendTo(li)
    li.appendTo(ul)

    panel = $('<div/>')
    panel.appendTo( @el ).addClass('tab-content')
    @tabPanels[ tabId ] = { handle: li, panel: panel, a: a }

    a.click (e) ->
      tabId = $(this).data('tabId')
      self.activate(tabId)
      return false
    cb panel if cb
    @activate tabId

  activate: (tabId) ->
    o = @tabPanels[ tabId ]
    if o
      @hidePanels()
      o.panel.show()
      @el.trigger('activatetab',[o.panel])
      @ul.find('.active').removeClass('active')
      o.a.addClass('active')

  removeTab: (tabId) ->
    o = @tabPanels[ tabId ]
    if o
      o.handle.remove()
      o.panel.remove()
      delete(@tabPanels[tabId])
