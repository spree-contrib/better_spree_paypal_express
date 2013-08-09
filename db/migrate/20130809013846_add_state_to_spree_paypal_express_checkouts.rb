class AddStateToSpreePaypalExpressCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_paypal_express_checkouts, :state, :string, :default => "complete"
  end
end
