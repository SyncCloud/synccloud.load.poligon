app = (require "express")()
serveStatic = require "serve-static"
bodyParser = require "body-parser"
jade = require "jade"
config = require "./config"
mongoose = require "mongoose"

app.use bodyParser.json()
app.use serveStatic('static')
app.engine "jade", require("jade").__express
app.set "port", config.port or process.env.PORT or 5000

app.use '/', require './router'

mongoose.connect "mongodb://#{config.mongo.host}:#{config.mongo.port}/#{config.mongo.db}"
mongoose.connection.once 'open', ->
  app.listen app.get('port'), ->
    console.log "app started at port #{app.get('port')}"
