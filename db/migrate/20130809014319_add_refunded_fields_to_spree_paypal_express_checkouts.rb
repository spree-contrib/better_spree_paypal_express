class AddRefundedFieldsToSpreePaypalExpressCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_paypal_express_checkouts, :refund_transaction_id, :string
    add_column :spree_paypal_express_checkouts, :refunded_at, :datetime
    add_column :spree_paypal_express_checkouts, :refund_type, :string
    add_column :spree_paypal_express_checkouts, :created_at, :datetime
  end
end
