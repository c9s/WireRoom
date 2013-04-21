
fs = require "fs"
glob = require "glob"
wrench = require "wrench"

class AppCache
  meta: { }
  cacheList: []
  networkList: []
  fallbackList: []

  configures: {}
  options: {}

  constructor: (@cacheFile, @options) ->
    # @cacheFile = ".appcache"
    if fs.existsSync(@cacheFile)
      @meta = JSON.parse(fs.readFileSync(@cacheFile,"utf8"))
    else
      @meta = { version: 0.01 }
    @bump()

    console.info "AppCache Manifest Version: v#{ @meta.version }"

    fs.writeFileSync(@cacheFile, JSON.stringify(@meta),"utf8")

  bump: () -> @meta.version = (Math.ceil(parseFloat(@meta.version) * 100) / 100) + 0.01

  configure: (mode,cb) ->
    @configures[ mode ] = cb
    this

  # when restarting version, we should bump the version
  version: (version) ->
    if version
      @meta.version = version
      return this
    return @meta.version

  network: (line) ->
    @networkList.push line
    this

  cache: (line) ->
    if line instanceof Array
      for a in line
        @cacheList.push a
    else
      @cacheList.push line
    this

  fallback: (line) ->
    @fallbackList.push line
    this

  clear: () ->
    @fallbackList = @networkList = @cacheList = []
    this

  write: ->
    mode = @options?.mode or "development"
    @configures[ mode ]?.call(this)

    if mode is "development" and not @configures[ mode ] \
      and not @cacheList.length \
      and not @networkList.length
        output = "CACHE MANIFEST\n"
        output += "# Version #{ @meta.version }\n"
        output += "NETWORK:\n"
        output += "*"
        return output
    else
      output = "CACHE MANIFEST\n"
      output += "# v#{ @meta.version }\n"
      output += "CACHE:\n" + @_expandList('cacheList').join("\n") if @cacheList.length
      output += "NETWORK:\n" + @networkList.join("\n") if @networkList.length
      output += "FALLBACK:\n" + @fallbackList.join("\n") if @fallbackList.length
    return output

  _expandPath: (path) ->
    # skip expand if there is a wild card.
    if typeof path is "string" and path.match(/\*/)
      return glob.sync(path)

    stats = fs.statSync(path)
    return if stats.isDirectory() \
      then wrench.readdirSyncRecursive(path) \
      else [path]

  _expandList: (listname) ->
    newlist = []
    item = @[listname]
    for item in list
      newlist.push path for path in @_expandPath(item)

    if @options.debug
      console.log listname
      console.log "- #{item} " for item in newlist
    return newlist

  route: ->
    self = this
    cached = ""
    return (req,res) ->

      res.writeHead(200, {
        "Content-Type": "text/plain; chartset=UTF-8"
      })
      if self.options.cache
        if not cached
          cached = self.write()
        res.write(cached)
      else
        res.write(self.write())
      res.end()

module.exports = AppCache
