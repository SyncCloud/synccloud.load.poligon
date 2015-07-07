_ = require "underscore"
request = require "request"
q = require "q"
url = require "url"
path = require "path"
moment = require "moment"
require "shelljs/global"
AWS = require "aws-sdk"
Logger = require './lib/logger'
require('./lib/aws-helpers').injectPromise AWS
AWS.config.update("accessKeyId": "AKIAJUTNEX6YKDSSZCSQ", "secretAccessKey": "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", "region": "eu-west-1")

Logger.logLevel = 'info'

errorExit = (args...) ->
  console.log args...
  exit 1

handleError = (err) ->
  console.log err, err.stack
  exit 1

if process.argv.length < 2 then errorExit "usage: tt load [frontendBranch] [backendBranch]"

[frontendBranch, apiBranch] = process.argv
apiBranch ?= frontendBranch

version="1.7.2"
hardware =
  db: 'c3.large'
  backend:
    count: 1
    type: 'c3.large'
    cache: '512MB'
  frontend:
    count: 2
    type: 'm3.medium'
  tank: 'm3.medium'

###
  Pre-check:
    - quay image
    - env version with this image should exists
    - backend version in s3 bucket
###

infrastructurePromise = require("./launchers/db") AWS, hardware.db
  .then (dbHost) ->
    q.Promise (resolve) ->
      require("./launchers/backend") AWS, "1.7.2", hardware.backend, "Server=#{dbHost};Initial Catalog=SiteTest;User Id=sa;Password=111222"
        .then (backendHost) ->
          resolve dbHost, backendHost
        .done()

tankLaunchPromise = require("./launchers/tank") AWS, hardware.tank

q.all [infrastructurePromise, tankLaunchPromise]
  .spread (infraHosts, tankHost) ->
    echo arguments
    for file in ls 'tests/ci/*.coffee'
      testSpecs = require './'+file
      if not _.isArray testSpecs
        testSpecs = [testSpecs]
      
      (for Test in testSpecs
        new Test
          appVersion: version
          hardware: hardware
          db:
            host: infraHosts[0]
          graphite:
            host: "ec2-54-195-205-175.eu-west-1.compute.amazonaws.com"
            port: 2003
            webPort: 80
          poligonUrl: "http://localhost:5000"
          tankHost: tankHost
          target:
            host: infraHosts[1]
            port: 80
      )
      .map (t) -> (-> t.run())
      .reduce q.when, q()
      .done()

#Clean test environment

