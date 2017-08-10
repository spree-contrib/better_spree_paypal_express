class RenamePaymentMethods < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      update spree_payment_methods set type = 'Spree::Gateway::PayPalExpress' WHERE type = 'Spree::BillingIntegration::PaypalExpress'
    SQL
  end

  def down
    execute <<-SQL
      update spree_payment_methods set type = 'Spree::BillingIntegration::PaypalExpress' WHERE type = 'Spree::Gateway::PayPalExpress'
    SQL
  end
end
