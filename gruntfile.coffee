loadTasks = require "load-grunt-tasks"

module.exports = (grunt) ->
  grunt.initConfig
    bower:
      dev:
        dest: 'static/vendor',
        options:
          expand: true

    coffee:
      options:
        sourceMap: true
        sourceMapDir: 'static/maps'
      compile:
        expand: true,
        flatten: true,
        cwd: 'static/coffee'
        src: ['*.coffee']
        dest: 'static/js'
        ext: '.js'

    browserify:
      main:
        options:
          debug: true
        files:
          'static/dist/index.js': ['static/js/index.js']
          'static/dist/report.js': ['static/js/report.js']
          'static/dist/compare.js': ['static/js/compare.js']

    nodemon:
      app:
        script: 'app.coffee',
        ext: 'js,coffee',
        ignore: ['node_modules/**']

    coffeeify:
      main:
        options:
          debug: true
        files: [
          src: ['static/coffee/index.coffee'], dest: 'static/dist/index.js'
          ,
            src: ['static/coffee/compare.coffee'], dest: 'static/dist/compare.js'
          ,
            src: ['static/coffee/report.coffee'], dest: 'static/dist/report.js'
        ]


    watch:
      coffee:
        files: "static/coffee/**/*.coffee",
        tasks: ['js']

  loadTasks grunt

  grunt.registerTask 'js', ['coffee', 'browserify']
  grunt.registerTask 'default', ['bower', 'js']


