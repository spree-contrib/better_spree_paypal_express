require 'paypal-sdk-merchant'
module Spree
  class Gateway::PayPalExpress < Gateway
    preference :login, :string
    preference :password, :string
    preference :signature, :string
    preference :server, :string, default: 'sandbox'
    preference :solution, :string, default: 'Mark'
    preference :landing_page, :string, default: 'Billing'
    preference :logourl, :string, default: ''
    # Indicates whether to display the shipping address on the paypal checkout
    # page.
    #
    # 0 - Paypal displays the shipping address on the page.
    # 1 - Paypal does not display the shipping address on its pages. This is
    #     the default due to the history of this gem.
    # 2 - Paypal will obtain the shipping address from the profile.
    preference :no_shipping, :string, default: '1'

    # Allow Address Override
    # 0 - Do not override the address stored at PayPal
    # 1 - Override the address stored at Paypal
    # By default, the shipping address is not overriden on Paypal's site
    preference :address_override, :string

    # Whether to require a confirmed address
    # 0 - Do not require a confirmed address
    # 1 - Require a confirmed address
    #
    # Paypal recommends that you do not override the address if you are
    # requiring a confirmed address for this order.
    preference :req_confirmed_address, :string

    def supports?(source)
      true
    end

    def provider_class
      ::PayPal::SDK::Merchant::API
    end

    def provider
      ::PayPal::SDK.configure(
        :mode      => preferred_server.present? ? preferred_server : "sandbox",
        :username  => preferred_login,
        :password  => preferred_password,
        :signature => preferred_signature)
      provider_class.new
    end

    def auto_capture?
      true
    end

    def method_type
      'paypal'
    end

    def purchase(amount, express_checkout, gateway_options={})
      pp_details_request = provider.build_get_express_checkout_details({
        :Token => express_checkout.token
      })
      pp_details_response = provider.get_express_checkout_details(pp_details_request)

      pp_request = provider.build_do_express_checkout_payment({
        :DoExpressCheckoutPaymentRequestDetails => {
          :PaymentAction => "Sale",
          :Token => express_checkout.token,
          :PayerID => express_checkout.payer_id,
          :PaymentDetails => pp_details_response.get_express_checkout_details_response_details.PaymentDetails
        }
      })

      pp_response = provider.do_express_checkout_payment(pp_request)
      if pp_response.success?
        # We need to store the transaction id for the future.
        # This is mainly so we can use it later on to refund the payment if the user wishes.
        transaction_id = pp_response.do_express_checkout_payment_response_details.payment_info.first.transaction_id
        express_checkout.update_column(:transaction_id, transaction_id)

        # We need to get a hold of the confirmed address
        address = extract_address(pp_details_response)

        if address && address.valid?
          express_checkout.update_column(:address_id, address.id)
        end

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

    def refund(payment, amount)
      refund_type = payment.amount == amount.to_f ? "Full" : "Partial"
      refund_transaction = provider.build_refund_transaction({
        :TransactionID => payment.source.transaction_id,
        :RefundType => refund_type,
        :Amount => {
          :currencyID => payment.currency,
          :value => amount },
        :RefundSource => "any" })
      refund_transaction_response = provider.refund_transaction(refund_transaction)
      if refund_transaction_response.success?
        payment.source.update_attributes({
          :refunded_at => Time.now,
          :refund_transaction_id => refund_transaction_response.RefundTransactionID,
          :state => "refunded",
          :refund_type => refund_type
        })

        payment.class.create!(
          :order => payment.order,
          :source => payment,
          :payment_method => payment.payment_method,
          :amount => amount.to_f.abs * -1,
          :response_code => refund_transaction_response.RefundTransactionID,
          :state => 'completed'
        )
      end
      refund_transaction_response
    end

    private

    def extract_address(response)
      return nil unless self.preferred_req_confirmed_address == '1'

      express_checkout_details = response.get_express_checkout_details_response_details
      payment_details = express_checkout_details.PaymentDetails.first
      payer_info = express_checkout_details.PayerInfo
      ship_to_address = payment_details.ShipToAddress

      return nil unless ship_to_address && payer_info

      if state = Spree::State.find_by_abbr(ship_to_address.state_or_province)
        Spree::Address.create(
          firstname: payer_info.payer_name.first_name,
          last_name: payer_info.payer_name.last_name,
          address1: ship_to_address.street1,
          address2: ship_to_address.street2,
          city: ship_to_address.city_name,
          state_id: state.id,
          state_name: state.name,
          country_id: state.country.id,
          zipcode: ship_to_address.postal_code,
          phone: ship_to_address.phone || "n/a"
        )
      end
    end
  end
end

#   payment.state = 'completed'
#   current_order.state = 'complete'
