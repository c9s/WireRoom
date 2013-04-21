if typeof window.console is "undefined"
  # make a fake console interface if there is no console support.
  window.console =
    log: () ->
    info: () ->
    error: () ->
    warn: () ->
