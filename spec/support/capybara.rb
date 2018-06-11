require 'capybara'
require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/poltergeist'

RSpec.configure do
  Capybara.javascript_driver = :poltergeist

  Capybara.register_driver(:poltergeist) do |app|
    Capybara::Poltergeist::Driver.new app, js_errors: true, timeout: 60, phantomjs_options: ['--ssl-protocol=TLSv1.2']
  end
end
