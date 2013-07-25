module Spree
  class PaypalController < StoreController
    def express
      items = current_order.line_items.map do |item|
        {
          :Name => item.product.name,
          :Quantity => item.quantity,
          :Amount => {
            :currencyID => current_order.currency,
            :value => item.price
          },
          :ItemCategory => "Physical"
        }
      end

      current_order.adjustments.credit.eligible.each do |credit|
        items << {
          :Name => credit.label,
          :Quantity => 1,
          :Amount => {
            :currencyID => current_order.currency,
            :value => credit.amount
          }
        }
      end
      pp_request = provider.build_set_express_checkout({
        :SetExpressCheckoutRequestDetails => {
          :ReturnURL => confirm_paypal_url(:payment_method_id => params[:payment_method_id]),
          :CancelURL =>  cancel_paypal_url,
          :PaymentDetails => [{
            :OrderTotal => {
              :currencyID => current_order.currency,
              :value => current_order.total },
            :ItemTotal => {
              :currencyID => current_order.currency,
              :value => items.sum { |i| i[:Quantity] * i[:Amount][:value] } },
            :ShippingTotal => {
              :currencyID => current_order.currency,
              :value => current_order.ship_total },
            :TaxTotal => {
              :currencyID => current_order.currency,
              :value => current_order.tax_total },
            :ShipToAddress => address_options,
            :PaymentDetailsItem => items,
            :ShippingMethod => "Shipping Method Name Goes Here",
            :PaymentAction => "Sale",
      }]}})
      pp_response = provider.set_express_checkout(pp_request)
      if pp_response.success?
        redirect_to provider.express_checkout_url(pp_response)
      else
        flash[:notice] = "PayPal failed. #{pp_response.errors.map(&:long_message).join(" ")}"
        redirect_to checkout_state_path(:payment)
      end
    end

    def confirm
      order = current_order
      order.payments.create!({
        :source => Spree::PaypalExpressCheckout.create({
            :token => params[:token],
            :payer_id => params[:PayerID]
        }, :without_protection => true),
        :amount => order.total,
        :payment_method => payment_method
      }, :without_protection => true)
      order.next
      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        redirect_to order_path(order, :token => order.token)
      else
        redirect_to checkout_state_path(order.state)
      end
    end

    def cancel
      binding.pry
    end

    private

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def provider
      payment_method.provider
    end

    def address_options
      {
        :Name => current_order.bill_address.try(:full_name),
        :Street1 => current_order.bill_address.address1,
        :Street2 => current_order.bill_address.address2,
        :CityName => current_order.bill_address.city,
        # :phone => current_order.bill_address.phone,
        :StateOrProvince => current_order.bill_address.state_text,
        :Country => current_order.bill_address.country.iso,
        :PostalCode => current_order.bill_address.zipcode
      }
    end
  end
end
