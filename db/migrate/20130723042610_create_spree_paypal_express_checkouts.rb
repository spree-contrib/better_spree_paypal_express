class CreateSpreePaypalExpressCheckouts < ActiveRecord::Migration[4.2]
  def change
    create_table :spree_paypal_express_checkouts do |t|
      t.string :token
      t.string :payer_id
    end
  end
end
