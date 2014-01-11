module.exports = function(grunt) {

  // Project Config
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    watch: {
      sass: {
        files: ['_sass/**.scss'],
        tasks: 'compass:dev'
      },
      javascripts: {
        files: ['_javascripts/**.js'],
        tasks: 'uglify'
      }
    },

    compass: {
      dist: {
        options: {
          sassDir: '_sass',
          cssDir: 'assets/stylesheets',
          environment: 'production'
        }
      },
      dev: {
        options: {
          sassDir: '_sass',
          cssDir: 'assets/stylesheets'
        }
      }
    },

    uglify: {
      all: {
        files: {
          'assets/javascripts/application.js': [
            'bower_components/jquery/jquery.js',
            '_javascripts/bootstrap/collapse.js',
            '_javascripts/application.js'
          ]
        }
      }
    },

    jekyll: {
      dev: {
        options: {
          serve: true,
          watch: true
        }
      }
    },

    concurrent: {
      tasks: ['watch', 'jekyll:dev'],
      options: {
        logConcurrentOutput: true
      }
    }

  });

  // Load Plugins
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-sass');
  grunt.loadNpmTasks('grunt-jekyll');
  grunt.loadNpmTasks('grunt-concurrent');
  grunt.loadNpmTasks('grunt-contrib-compass');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-copy');

  // Default Task
  grunt.registerTask('default', ['concurrent'])

};
