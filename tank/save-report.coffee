request = require "request"
require "shelljs/global"

request.post
      url: "http://localhost:5000/report"
      json: true
      body: JSON.parse cat('./report.json')
    , (err, resp, body) ->
      if err then console.log "error when generating report", err
      else echo body