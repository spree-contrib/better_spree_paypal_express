require 'spec_helper'

describe Spree::Gateway::PayPalExpress do
  let(:gateway) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress", :environment => Rails.env) }

  context "payment purchase" do
    # Test for #4
    it "fails" do
      payment = FactoryGirl.create(:payment, :payment_method => gateway)
      payment.stub :source => mock_model(Spree::PaypalExpressCheckout, :token => '', :payer_id => '')
      provider = double('Provider')
      gateway.stub(:provider => provider)
      provider.should_receive(:build_do_express_checkout_payment)
      response = double('pp_response', :success? => false, 
                          :errors => [double('pp_response_error', :long_message => "An error goes here.")])
      provider.should_receive(:do_express_checkout_payment).and_return(response)
      lambda { payment.purchase! }.should raise_error(Spree::Core::GatewayError, "An error goes here.")
    end
  end
end
