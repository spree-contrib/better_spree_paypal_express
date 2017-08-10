class AddStateToSpreePaypalExpressCheckouts < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_paypal_express_checkouts, :state, :string, :default => "complete"
  end
end
