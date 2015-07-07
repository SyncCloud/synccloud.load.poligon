LoadTest = require "../lib/test"

class GetEmployeeByIdTest extends LoadTest
  name: "/api/employees/:id"
  description: 'Getting employee profile'
  category: 'endpoint_load'
  auth: ['one', 'nick']
  uris: [
    "/api/employees/1"
  ]
  rps_schedule: 'line(1, 70, 40s)'

module.exports = GetEmployeeByIdTest
