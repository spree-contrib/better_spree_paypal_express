module SpreePaypalExpress
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, :type => :boolean, :default => false

      def add_javascripts
        append_file 'app/assets/javascripts/store/all.js', "//= require store/spree_paypal_express\n"
        append_file 'app/assets/javascripts/admin/all.js', "//= require admin/spree_paypal_express\n"
      end

      def add_stylesheets
        application_css_sass = "app/assets/stylesheets/application.css.sass"
        application_css_scss = "app/assets/stylesheets/application.css.scss"
        application_css = "app/assets/stylesheets/application.css"

        css_file = application_css_sass if File.exist?(application_css_sass)
        css_file = application_css_scss if File.exist?(application_css_scss)
        css_file ||= application_css

        inject_into_file css_file, " *= require store/spree_paypal_express\n", :before => /\*\//, :verbose => true
        inject_into_file css_file, " *= require admin/spree_paypal_express\n", :before => /\*\//, :verbose => true
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_paypal_express'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
