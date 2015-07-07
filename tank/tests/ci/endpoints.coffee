LoadTest = require "../../lib/test"
defaults = 
  rps_schedule: 'line(1, 100, 30s)'
  autostop: ['negative_net(0,10%,10s)']

class GetEmployeeProfile extends LoadTest
  name: "/api/employees/:id"
  description: 'Getting all colleagues profiles'
  auth: ['one', 'nick']
  autostop: defaults.autostop
  uris: -> @data.getAllColleagues('nick').then (ids) -> ids.map (id) -> "/api/employees/#{id}"
  rps_schedule: defaults.rps_schedule

class GetTaskPage extends LoadTest
  name: "/tasks/:id"
  description: 'Loading all tasks pages per user'
  auth: ['one', 'nick']
  autostop: defaults.autostop
  uris: -> @data.getAllTasks('nick').then (ids) -> ids.map (id) -> "/tasks/#{id}"
  rps_schedule: defaults.rps_schedule

class GetProjectPage extends LoadTest
  name: "/projects/:id"
  description: 'Loading all projects pages per user'
  auth: ['one', 'nick']
  autostop: defaults.autostop
  uris: -> @data.getAllTasks('nick').then (ids) -> ids.map (id) -> "/projects/#{id}"
  rps_schedule: defaults.rps_schedule

class GetCompanyPage extends LoadTest
  name: "/company"
  description: 'Load urers\' company page'
  auth: ['one', 'nick']
  autostop: defaults.autostop
  uris: ['/company']
  rps_schedule: defaults.rps_schedule

class GetDocs extends LoadTest
  name: "/api/docs"
  description: 'Get docs list for various categories'
  auth: ['one', 'nick']
  autostop: defaults.autostop
  uris: -> @api(url:'/api/docs/counts').then (resp) ->
    (for cat, subcats of resp
      for subcat, count of subcats
        "/api/docs?category=#{cat}&subcategory=#{subcat}")
  rps_schedule: defaults.rps_schedule

module.exports = [GetEmployeeProfile, GetTaskPage, GetProjectPage, GetCompanyPage]
