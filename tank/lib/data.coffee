Logger = require './logger'
db = require('odbc')()
q = require 'q'
config = require '../../conf'
connIndex = 0

class DataManager extends Logger
  @makeConnectionString: (host) ->
    "Driver={#{config.odbcDriver}};Server={#{host}};Port=1433;Database=SiteTest;Uid=sa;Pwd=111222;"
  constructor: (host) ->
    @connectionString = DataManager.makeConnectionString(host)
  _query: (params...) ->
    q.Promise (resolve, reject) =>
      db.open @connectionString, (err) =>
        curIndex = ++connIndex
        @info "connection #{connIndex} opened"
        if err? then reject err
        else
          db.query params..., (err, data) =>
            db.close => @info "connection #{curIndex} closed"
            if err then reject err
            else resolve data
  getAllUsers: ->
    @_query """
      select username, ID_Employee employeeId
        from Employers e
          join aspnet_Users on UserId=ID_User
    """
  getAllColleagues: (username) ->
    @_query """
      select ID_Employee id
        from Employers
        where CompanyId in (select CompanyId
          from aspnet_Users
            join Employers on ID_USER = UserId
          where username='#{username}')
    """
    .then (rows) -> rows.map (r) -> r.id
  getAllTasks: (username, count=100) ->
    @_query """
      select top #{count} ID_Task id from authTasks ((
        select ID_Employee 
          from Employers 
            join aspnet_users on ID_User = UserId 
          where username='#{username}'))
    """
    .then (rows) -> rows.map (r) -> r.id
  getAllProjects: (username, count=100) ->
    @_query """
      with emp as (
        select ID_Employee 
          from Employers 
            join aspnet_users on ID_User = UserId 
          where username='#{username}'
      )
      select top #{count} ID_Project id from Projects where ProjectManagerID in (select * from emp) or CreatorEmployeeID in (select * from emp) 
    """
    .then (rows) -> rows.map (r) -> r.id

module.exports = DataManager