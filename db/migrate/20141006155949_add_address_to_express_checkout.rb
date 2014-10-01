class AddAddressToExpressCheckout < ActiveRecord::Migration
  def change
    add_reference :spree_paypal_express_checkouts, :address
  end
end
