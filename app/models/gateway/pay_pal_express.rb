module Spree
  class Gateway::PayPalExpress < Gateway
    preference :login, :string
    preference :password, :string
    preference :signature, :string

    attr_accessible :preferred_login, :preferred_password, :preferred_signature

    def provider_class
      ActiveMerchant::Billing::PaypalGateway
    end
  end
end