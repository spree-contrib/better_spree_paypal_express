module Spree
  class PaypalExpressCheckout < ActiveRecord::Base

    # add payment actions here...
    # %w{capture credit}
    def actions
      %w{credit}
    end

    def can_credit?(payment)
      return false unless payment.state == "completed"
      return false unless payment.order.payment_state == "credit_owed"
      return false unless payment.payment_method.payment_profiles_supported?
      payment.credit_allowed > 0
    end

  end
end