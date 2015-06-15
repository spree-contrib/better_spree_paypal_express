module Spree
  class Paypal
    include ActiveModel::SerializerSupport

    ## simple poro to make serializing easy
    # http://blog.honeybadger.io/poro-plain-old-ruby-object-tests-and-specs/
    #
    # maybe this functionality should be rolled into 
    # the paypal express checkout object or be called paypal express idk
    #
    attr_accessor :redirect_url
  end
end
