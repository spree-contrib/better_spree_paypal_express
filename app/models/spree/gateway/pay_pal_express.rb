require 'paypal-sdk-merchant'
module Spree
  class Gateway::PayPalExpress < Gateway
    preference :login, :string
    preference :password, :string
    preference :signature, :string

    attr_accessible :preferred_login, :preferred_password, :preferred_signature

    def provider_class
      PayPal::SDK::Merchant::API.new
    end

    def provider
      PayPal::SDK.configure(
        :mode      => "sandbox",  # Set "live" for production
        :username  => preferred_login,
        :password  => preferred_password,
        :signature => preferred_signature)
      provider_class
    end

    def auto_capture?
      true
    end

    def method_type
      'paypal'
    end

    def purchase(amount, express_checkout, gateway_options={})
      pp_request = provider.build_do_express_checkout_payment({
        :DoExpressCheckoutPaymentRequestDetails => {
          :PaymentAction => "Sale",
          :Token => express_checkout.token,
          :PayerID => express_checkout.payer_id,
          :PaymentDetails => [{
            :OrderTotal => {
              :currencyID => Spree::Config[:currency],
              :value => amount }
          }]
        }
      })

      pp_response = provider.do_express_checkout_payment(pp_request)
      if pp_response.success?
        # This is rather hackish, required for payment/processing handle_response code.
        return Struct.new(:success?, :authorization).new(true, nil)
      else
        # TODO: Handle a fail case.
      end
    end
  end
end

#   payment.state = 'completed'
#   current_order.state = 'complete'