module Spree
  class PaypalExpressCheckout < ActiveRecord::Base
    def actions
      %w{capture}
    end
  end
end