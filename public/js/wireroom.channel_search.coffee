class window.WRChannelSearchInput
  constructor: (@wireroom, @form) ->
    self = this
    @searchInput = @form.find('input')
    @form.submit (e) ->
      room = self.searchInput.val()
      self.wireroom.joinChannel room
      return false

