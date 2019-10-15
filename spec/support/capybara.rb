require 'capybara'
require 'capybara/rspec'
require 'capybara/rails'
require 'selenium-webdriver'
require 'webdrivers'

RSpec.configure do |config|
  Capybara.register_driver :chrome do |app|
    Selenium::WebDriver.logger.level = :error

    Capybara::Selenium::Driver.new app,
      browser: :chrome,
      options: Selenium::WebDriver::Chrome::Options.new(args: %w[disable-popup-blocking headless disable-gpu window-size=1920,1080])
  end

  Capybara.javascript_driver = :chrome
end
