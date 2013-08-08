class AddTransactionIdToSpreePaypalExpressCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_paypal_express_checkouts, :transaction_id, :string
    add_index :spree_paypal_express_checkouts, :transaction_id
  end
end
