loadTasks = require "load-grunt-tasks"

module.exports = (grunt) ->
  grunt.initConfig
    bower: 
      dev:
        dest: 'static/vendor',
        options:
          expand: true
          

  loadTasks grunt    

  grunt.registerTask 'default', ['bower', 'copy']


