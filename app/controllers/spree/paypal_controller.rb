module Spree
  class PaypalController < StoreController
    def express
      # TODO: support adjustments
      # Check out the old spree_paypal_express for how it does this
      # Specifically, look for "credits" in CheckoutController decorator
      items = current_order.line_items.map do |item|
        { name: item.variant.name,
          description: item.variant.description[0..120],
          quantity: item.quantity,
          # TODO: For 2.1.0, make this just item.money.cents
          amount: item.money.money.cents }
      end

      # TODO: For 2.1.0, make this display_item_total.cents
      response = provider.setup_purchase(current_order.display_item_total.money.cents,
        ip: request.remote_ip,
        return_url: confirm_paypal_url(:payment_method_id => params[:payment_method_id]),
        cancel_return_url: cancel_paypal_url,
        currency: current_order.currency,
        locale: I18n.locale.to_s.sub(/-/, '_'),
        brand_name: Spree::Config[:site_name],
        address: address_options,
        header_image: 'http://teclacolorida.com/assets/images/logos/schoooools.png',
        allow_guest_checkout: 'true',   #payment with credit card for non PayPal users
        items: items
      )

      redirect_to provider.redirect_url_for(response.token)
    end

    def confirm
      details = provider.details_for(params[:token])
      payer_id = details.payer_id
      # TODO: For 2.1.0, make this display_item_total.cents
      response = provider.purchase(current_order.display_item_total.money.cents, {
        ip: request.remote_addr,
        token: params[:token],
        payer_id: payer_id,
        currency: current_order.currency
      })
      # TODO: Add payment to order
    end

    def cancel
      binding.pry

    end

    private

    def provider
      Spree::PaymentMethod.find(params[:payment_method_id]).provider
    end

    def address_options
      {
        :name => current_order.bill_address.try(:full_name),
        :zip => current_order.bill_address.zipcode,
        :address1 => current_order.bill_address.address1,
        :address2 => current_order.bill_address.address2,
        :city => current_order.bill_address.city,
        :phone => current_order.bill_address.phone,
        :state => current_order.bill_address.state_text,
        :country => current_order.bill_address.country.iso
      }
    end
  end
end
