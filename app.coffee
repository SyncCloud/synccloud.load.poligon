app = (require "express")()
serveStatic = require "serve-static"
bodyParser = require "body-parser"
jade = require "jade"
mongoose = require "mongoose"

app.use bodyParser.json()
app.use serveStatic('static')
app.engine "jade", require("jade").__express
app.set "port", 5000

app.use '/', require './router'

mongoose.connect "mongodb://localhost/grafinchik"
db = mongoose.connection
db.once 'open', ->
  app.listen app.get('port'), ->
    console.log "app started at port #{app.get('port')}"
