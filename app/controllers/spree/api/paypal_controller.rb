module Spree
  module Api
    class PaypalController < Spree::Api::BaseController
      ssl_allowed

      def express

        order = current_order || raise(ActiveRecord::RecordNotFound)
        items = order.line_items.map(&method(:line_item))

        tax_adjustments = order.all_adjustments.tax.additional
        shipping_adjustments = order.all_adjustments.shipping

        order.all_adjustments.eligible.each do |adjustment|
          next if (tax_adjustments + shipping_adjustments).include?(adjustment)
          items << {
            :Name => adjustment.label,
            :Quantity => 1,
            :Amount => {
              :currencyID => order.currency,
              :value => adjustment.amount
            }
          }
        end

        # Because PayPal doesn't accept $0 items at all.
        # See #10
        # https://cms.paypal.com/uk/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECCustomizing
        # "It can be a positive or negative value but not zero."
        items.reject! do |item|
          item[:Amount][:value].zero?
        end
        pp_request = provider.build_set_express_checkout(express_checkout_request_details(order, items))

        # Trying to conform to https://guides.spreecommerce.com/api/summary.html
        # as much as possible
        begin
          pp_response = provider.set_express_checkout(pp_request)
          if pp_response.success?
            url = provider.express_checkout_url(pp_response, :useraction => 'commit')
            @paypal_response = Spree::Paypal.new
            @paypal_response.redirect_url = url
            render json: @paypal_response.to_json, status: 200
          else
            # this one is easy we can just respond with pp_response errors
            render json: {errors:pp_response.errors.collect(&:long_message).join(" ")}, status: 500
          end
        rescue SocketError
          render json: {errors:[Spree.t('flash.connection_failed', :scope => 'paypal')]}, status: 500
        end
      end

      def confirm
        order = current_order || raise(ActiveRecord::RecordNotFound)
        order.payments.create!({
          :source => Spree::PaypalExpressCheckout.create({
            :token => params[:token],
            :payer_id => params[:PayerID]
          }),
          :amount => order.total,
          :payment_method => payment_method
        })
        
        # using code from regular controller as psuedocode comment for what you are need to do on frontend now
        #
        # order.next # move order to next state
        #
        # if order.complete?
        #   flash.notice = Spree.t(:order_processed_successfully)
        #   redirect_to completion_route(order)
        # else
        #   redirect_to checkout_state_path(order.state)
        # end
        render json: order.to_json, status: 200
      end

      def cancel
        # unneeded in api version where paypal calls back to client first
        # you can just do this client side
        #
        # flash[:notice] = Spree.t('flash.cancel', :scope => 'paypal')
        # order = current_order || raise(ActiveRecord::RecordNotFound)
        # redirect_to checkout_state_path(order.state, paypal_cancel_token: params[:token])

        render status: 200
      end

      private

      def current_order
        @order = Spree::Order.find_by(number: order_id)
      end

      def line_item(item)
        {
            :Name => item.product.name,
            :Number => item.variant.sku,
            :Quantity => item.quantity,
            :Amount => {
                :currencyID => item.order.currency,
                :value => item.price
            },
            :ItemCategory => "Physical"
        }
      end

      def express_checkout_request_details order, items
        { :SetExpressCheckoutRequestDetails => {
            :InvoiceID => order.number,
            :BuyerEmail => order.email,
            # Here we tell paypal redirect to client and have the client post back status to rails server
            :ReturnURL => params[:confirm_url],
            :CancelURL => params[:cancel_url],
            :SolutionType => payment_method.preferred_solution.present? ? payment_method.preferred_solution : "Mark",
            :LandingPage => payment_method.preferred_landing_page.present? ? payment_method.preferred_landing_page : "Billing",
            :cppheaderimage => payment_method.preferred_logourl.present? ? payment_method.preferred_logourl : "",
            :NoShipping => 1,
            :PaymentDetails => [payment_details(items)]
        }}
      end


      def payment_method
        Spree::PaymentMethod.find(params[:payment_method_id])
      end

      def provider
        payment_method.provider
      end

      def payment_details items
        # This retrieves the cost of shipping after promotions are applied
        # For example, if shippng costs $10, and is free with a promotion, shipment_sum is now $10
        shipment_sum = current_order.shipments.map(&:discounted_cost).sum

        # This calculates the item sum based upon what is in the order total, but not for shipping
        # or tax.  This is the easiest way to determine what the items should cost, as that
        # functionality doesn't currently exist in Spree core
        item_sum = current_order.total - shipment_sum - current_order.additional_tax_total

        if item_sum.zero?
          # Paypal does not support no items or a zero dollar ItemTotal
          # This results in the order summary being simply "Current purchase"
          {
            :OrderTotal => {
              :currencyID => current_order.currency,
              :value => current_order.total
            }
          }
        else
          {
            :OrderTotal => {
              :currencyID => current_order.currency,
              :value => current_order.total
            },
            :ItemTotal => {
              :currencyID => current_order.currency,
              :value => item_sum
            },
            :ShippingTotal => {
              :currencyID => current_order.currency,
              :value => shipment_sum,
            },
            :TaxTotal => {
              :currencyID => current_order.currency,
              :value => current_order.additional_tax_total
            },
            :ShipToAddress => address_options,
            :PaymentDetailsItem => items,
            :ShippingMethod => "Shipping Method Name Goes Here",
            :PaymentAction => "Sale"
          }
        end
      end

      def address_options
        return {} unless address_required?

        address_to_bill = current_order.bill_address || current_order.ship_address 
        {
            :Name => address_to_bill.try(:full_name),
            :Street1 => address_to_bill.address1,
            :Street2 => address_to_bill.address2,
            :CityName => address_to_bill.city,
            :Phone => address_to_bill.phone,
            :StateOrProvince => address_to_bill.state_text,
            :Country => address_to_bill.country.iso,
            :PostalCode => address_to_bill.zipcode
        }
      end

      def completion_route(order)
        order_path(order, :token => order.guest_token)
      end

      def address_required?
        payment_method.preferred_solution.eql?('Sole')
      end
    end
  end
end
