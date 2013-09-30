module Spree
  CheckoutController.class_eval do

    before_filter :redirect_to_paypal_express_form_if_needed, :only => [:update]

    def redirect_to_paypal_express_form_if_needed
      return unless (params[:state] == "payment")
      return unless params[:order][:payments_attributes]

      payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      return unless payment_method.kind_of?(Spree::Gateway::PayPalExpress)# || payment_method.kind_of?(Spree::Gateway::PaypalExpressUk)

      update_params = object_params.dup
      update_params.delete(:payments_attributes)
      if @order.update_attributes(update_params)
        fire_event('spree.checkout.update')
        render :edit and return unless apply_coupon_code
      end

      load_order
      if not @order.errors.empty?
         render :edit and return
      end

      redirect_to(paypal_express_url(:payment_method_id => payment_method.id)) and return
    end

  end
end