require 'paypal-sdk-merchant'
module Spree
  class Gateway::PayPalExpress < Gateway
    preference :login, :string
    preference :password, :string
    preference :signature, :string
    preference :server, :string, default: 'sandbox'

    #Commented out for Rails4 compatibility
    #attr_accessible :preferred_login, :preferred_password, :preferred_signature

    def provider_class
      ::PayPal::SDK::Merchant::API.new
    end

    def provider
      ::PayPal::SDK.configure(
          :mode      => preferred_server.present? ? preferred_server : "sandbox",
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
                  :value => ::Money.new(amount, Spree::Config[:currency]).to_s }
          }]
      }
  })

      pp_response = provider.do_express_checkout_payment(pp_request)
      if pp_response.success?
        # We need to store the transaction id for the future.
        # This is mainly so we can use it later on to refund the payment if the user wishes.
        transaction_id = pp_response.do_express_checkout_payment_response_details.payment_info.first.transaction_id
        express_checkout.update_column(:transaction_id, transaction_id)
        # This is rather hackish, required for payment/processing handle_response code.
        Class.new do
          def success?; true; end
          def authorization; nil; end
        end.new
      else
        class << pp_response
          def to_s
            errors.map(&:long_message).join(" ")
          end
        end
        pp_response
      end
    end
  end
end

#   payment.state = 'completed'
#   current_order.state = 'complete'