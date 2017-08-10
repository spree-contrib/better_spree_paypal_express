class AddTransactionIdToSpreePaypalExpressCheckouts < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_paypal_express_checkouts, :transaction_id, :string
    add_index :spree_paypal_express_checkouts, :transaction_id
  end
end
