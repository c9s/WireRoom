util = require('util')
vm = require('vm')
fs = require("fs")
coffee = require("coffee-script")
sync = require("sync")

module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"
    uglify:
      options:
        banner: "/*! <%= pkg.name %> <%= grunt.template.today(\"yyyy-mm-dd\") %> */\n"
      dist:
        src: "src/<%= pkg.name %>.js"
        dest: "dist/<%= pkg.name %>.min.js"

  # Load the plugin that provides the "uglify" task.
  grunt.loadNpmTasks "grunt-contrib-uglify"

  # XXX: seems not working in gruntjs
  grunt.registerTask "server", "start server" ,->
    startServer = ->
      require "./app.coffee"
    code = fs.readFileSync("app.coffee","utf8")
    sync ->
      startServer.sync()
    # require coffee.run(code)
    # vm.runInThisContext coffee.compile code
    # vm.runInNewContext coffee.compile(code)

  # Default task(s).
  # grunt.registerTask "default", ["uglify"]
  grunt.registerTask "default", []
