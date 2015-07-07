require "shelljs/global"
request = require "request"
moment = require "moment"
url = require 'url'
_ = require "underscore"
q = require 'q'
Logger = require "./logger"
Authentificator = require './auth'
DataManager = require './data'

class LoadTest extends Logger
  _authCookieName: '.ASPXAUTH'
  headers: {}
  uris: ["/"]

  preRun: (callback) ->
    do callback

  constructor: (options) ->
    _.extend @, options
    @_authentificator = new Authentificator @target.host, @db.host
    @data = new DataManager @db.host

  _setAuthHeaders: (token) ->
    if (@auth)
      @headers['Cookie']=@_authCookieName+'='+token

  _buildSection: (name, params) ->
    s = "[#{name}]\n" + (for name,value of params when value?
      "#{name} = "+(if _.isArray(value) then value.join('\n  ') else value)
      ).join('\n')

  _formatHeaders: ->
    "[#{k}: #{v}]" for k,v of @headers

  _resolveUris: ->
    q.Promise (resolve, reject) =>
      if _.isFunction @uris
        @uris().then(resolve).done()
      else resolve @uris
  api: (params, username='nick') ->
    params.url = url.resolve "http://#{@target.host}:#{@target.port}", params.url
    params.json = true
    q.Promise (resolve, reject) =>
      @_authentificator.getTokenForUsername(username).then (token) =>
        headers = params.headers or {}
        headers.Cookie = @_authCookieName+'='+token
        params.headers = headers
        request.get params, (err, resp, body) ->
          if err then reject err
          else resolve body.data
      .done()
  generateTankIni: () ->
    q.Promise (resolve, reject) =>
      authFn = @auth[0]
      if authFn is 'one'
        q.all [
          @_authentificator.getTokenForUsername(@auth[1]),
          @_resolveUris()
        ]
        .spread (token, uris) =>
          @_setAuthHeaders token
          sections=[]
          sections.push @_buildSection 'phantom',
            address: @target.host
            port: @target.port
            rps_schedule: @rps_schedule
            headers: @_formatHeaders()
            uris: uris

          if @graphite
            sections.push @_buildSection 'graphite',
              address: @graphite.host
              port: @graphite.port
              web_port: @graphite.webPort
          resolve sections.join('\n')
          return
        .done()
      else
        reject new Error "Auth method #{authFn} is not implemented yet"

  # Запускает тест на удаленном сервере
  run: ->
    q.Promise (resolve, reject) =>
      @preRun =>
        @info "##### running test #{@name} ######"
        @generateTankIni().then (@_iniGenerated) =>
          @info "===== start of #{@name} =========="
          # @info @_iniGenerated
          @info "===== end of #{@name} ============"
          @_iniGenerated.to "test.ini"
          exec "ssh -i ~/.ssh/tools.pem ubuntu@#{@tankHost} rm -rf /var/tests/*"
          exec "scp -i ~/.ssh/tools.pem ./test.ini ubuntu@#{@tankHost}:/var/tests/"
          @runStartTime = new Date
          exec "ssh -i ~/.ssh/tools.pem ubuntu@#{@tankHost} 'cd /var/tests && yandex-tank -o console.short_only=1 -c test.ini'"
          @runEndTime = new Date
          # exec "scp  -i ~/.ssh/tools.pem -r ubuntu@#{@tankHost}:/var/tests results/"
          rm "./test.ini"
          report = @_makeReport()
          if @poligonUrl
            @_sendReport(report).then( -> resolve report).done()
          else resolve report
          @info "##### completed test #{@name} ######"
        .done()

  # Формирует отчет с результатами тестирования
  _makeReport: ->
    name: @name
    description: @description
    infrastructure: @hardware
    appVersion: @appVersion
    startTimestamp: +@runStartTime
    endTimestamp: +@runEndTime
    rpsSchedule: @rps_schedule
    artifacts:
      tankIni: @_iniGenerated
  
  # Отправляет отчет на сервер
  _sendReport: (report) ->
    q.Promise (resolve, reject) =>
      request.post
        url: "#{@poligonUrl}/report"
        json: true
        body: report
      , (err, resp, body) =>
        if err? then reject err
        else
          @info "Response from poligon:"
          @info body
          resolve()

module.exports = LoadTest
