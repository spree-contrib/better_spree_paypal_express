module Spree
  class PaypalExpressCheckout < ActiveRecord::Base
    belongs_to :address, class_name: "Spree::Address"
    alias_attribute :confirmed_address, :address
  end
end
