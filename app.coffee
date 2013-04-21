
host = "0.0.0.0"
http = require("http")
path = require("path")
fs   = require("fs")
connect = require("connect")
console = require("console")
express = require("express")
stylus  = require('stylus')
github  = require('github')
require("js-yaml")

mongolian = require('mongolian')

class AppService
  constructor: () ->
  init: (app) ->
  start: () ->
  stop: () ->

class SocketIOService extends AppService

class IRCService extends AppService
  init: (app) ->
  start: () ->
  stop: () ->


class WireRoomBacklog

  @services: []

  constructor: (@db) ->

  queue: (room) ->
    queueName = if room then "queue-#{ room }" else "queue-broadcast"
    return @db.collection(queueName)

  append: (room,data) ->
    queue = @queue(room)
    queue.insert(data)

  ask: (room,limit) ->
    queue = @queue(room)
    return queue.find().limit(limit).sort({ timestamp: -1 })

class WireRoomNickList
  constructor: (@wireroom) ->

class WireRoom

  constructor: (@options) ->
    routes = require("./routes")
    self = this

    @config = @readConfig(@options.config)
    @socket = require('socket.io')

    @app = express()
    @app.configure =>
      @app.set("port", @config.Port)
      @app.set("views", __dirname + "/views")
      @app.enable "trust proxy"
      @app.use(connect.logger("dev"))
      @app.use(connect.favicon())
      @app.use(connect.cookieParser( @config.Cookie?.Secret ))
      @app.use(connect.bodyParser())
      @app.use(connect.methodOverride())
      @app.use(connect.session({ secret: "keyboard cat", key: "sid", cookie: { secure: true }}))
      @app.use(stylus.middleware({
        src: __dirname + "/public"
        dest: __dirname + "/public"
        # compress: true
        debug: true
      }))
      @app.use(connect.static("./public"))
      @app.use(@app.router)
    @app.configure "development", =>
      @app.use(express.errorHandler())
    # express --sessions --css stylus --ejs myapp
    # set view engine to ejs
    @app.set('view engine', 'ejs')
    # app.set('view options', { layout: false })

    @app.get "/", routes.index
    @app.get "/manifest.appcache", routes.appcache

    @server = http.createServer(@app)

    @db = new mongolian('mongo://127.0.0.1:27017/wireroom')

    @backlog = new WireRoomBacklog(@db)

    RedisStore = require('socket.io/lib/stores/redis')
    @redis  = require('socket.io/node_modules/redis')
    pub    = @redis.createClient()
    sub    = @redis.createClient()
    @redisClient = @redis.createClient()
    @io = io = @socket.listen(@server)

    @redisStore = new RedisStore({
      "redis": @redis
      "redisPub": pub
      "redisSub": sub
      "redisClient": @redisClient
    })

    @io.set "log level", 2
    @io.set "store", @redisStore

#      @io.set "authorization",  (data, accept) ->
#        data.sessionID = "random"
#        return accept(null, true)
#  
#        # check if there's a cookie header
#        if data.headers.cookie
#          # if there is, parse the cookie
#          data.cookie = parseCookie(data.headers.cookie)
#          # note that you will need to use the same key to grad the
#          # session id, as you specified in the Express setup.
#          data.sessionID = data.cookie['express.sid']
#        else
#          # if there isn't, turn down the connection with a message
#          # and leave the function.
#          return accept('No cookie transmitted.', false)
#        # accept the incoming connection
#        accept(null, true)

    @io.sockets.on "connection", (socket) =>
      console.log "A socket with sessionID " + socket.handshake.sessionID

      socket.on "backlog", (data) ->
        logs = self.backlog.ask(data.room,data.limit)
        logs.toArray (err,list) ->
          list.reverse()
          for log in list
            socket.emit("message.says",log)

      socket.on "leave", (data) ->
        console.log "Leave", data
        socket.leave(data.room)
        self.redisClient.hdel("nicks-#{data.rooms}",socket.id)
        io.sockets.in(data.room).emit("leave",data)

      socket.on "join", (data) ->
        console.log "Join", data
        socket.join(data.room)
        self.redisClient.hset("nicks-#{data.rooms}",socket.id,"1")

        io.sockets.in(data.room).emit("join",data)

        # get backlog from room backlog queue

        # rooms of a clients
        # console.log io.sockets.manager.roomClients[socket.id]

        # io.sockets.sockets
        # hash, contains socket objects (by socket.id)

        # clients of a room
        # console.log io.sockets.clients('room')

        # all rooms
        # io.sockets.manager.rooms

      socket.on "message.publish", (data) ->
        # force update timestamp
        data.timestamp = parseInt((new Date).getTime()/1000)
        if data.room
          io.sockets.in(data.room).emit('message.says', data)
        else
          io.sockets.emit('message.says', data)

        # save message in backlog queue.
        self.backlog.append(data.room,data)

      socket.on "disconnect", ->
        console.log "Disconnect"
        # socket.broadcast.emit('nicknames', nicknames)

  registerService: (service) ->
    service.init()
    @services.push service

  startServices: () ->
    for s in @services
      s.start()

  stopServices: () ->
    for s in @services
      s.stop()

  listen: ->
    @server.listen @config.Port, =>
      console.info("Listening at http://#{ @config.Host }:#{ @config.Port }/")

  readConfig: (file) ->
    config = require(file)
    config.Port = process.env.PORT or config.Port or 3000
    config.Host or= "0.0.0.0"
    return config

wireroom = new WireRoom({
  config: "./config/application.yml"
})
wireroom.listen()
