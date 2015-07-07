q = require 'q'
request = require 'request'
DataManager = require './data.coffee'

token = '8B2AF9B69B160346CAF41F24ECF82F62BCAD52C27515600B0CC30FE926B1C8A0E26CE0356880C06C02DF6F40DD00DD734F6A4561CAAA064AEF3857CF79779C742FD760FE1CE79156801D1D53F7CBB6DA438F8751'
cache={}

class Auth
  constructor: (@backendHost, dbHost) ->
    @data = new DataManager dbHost
  getTokenForUsername: (username) ->
    q.Promise (resolve, reject) =>
      if cache[username]? 
        console.log "taking from cache token for #{username}"
        resolve cache[username]
      else
        console.log "getting token for #{username}"
        request.post
          url: "http://#{@backendHost}/auth"
          headers:
            Accept: '*/*'
          form: 
            loginOrEmail: username
            password: '111222'
        , (err, resp) ->
          if err then reject err
          else
            token = resp.headers['set-cookie'][0].split(';')[0].split('=')[1]
            cache[username]=token
            resolve token
      return
  getAllTokens: ->
    q.Promise (resolve, reject) =>
      @data.getAllUsers().then (usernames) =>
        q.all (@getTokenForUsername u for u in usernames)
          .spread (tokens) ->
            resolve tokens
          .done()
      .done()

module.exports = Auth
