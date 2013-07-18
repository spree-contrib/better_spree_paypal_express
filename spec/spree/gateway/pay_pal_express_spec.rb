require 'spec_helper'

describe Spree::Gateway::PayPalExpress do
  let(:gateway) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress") }

  context "provider_class" do
    it "is a PayPalExpress gateway" do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::PaypalExpressGateway
    end

    it "return 'paypal' as method type" do
      expect(gateway.method_type).to eq "paypal"
    end
  end
end
