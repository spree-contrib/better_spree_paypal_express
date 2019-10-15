module CapybaraExt
  def wait_for(options = {})
    default_options = { error: nil, seconds: 5 }.merge(options)
  
    Selenium::WebDriver::Wait.new(timeout: default_options[:seconds]).until { yield }
  rescue Selenium::WebDriver::Error::TimeOutError
    default_options[:error].nil? ? false : raise(default_options[:error])
  end

  RSpec.configure do |c|
    c.include CapybaraExt
  end
end