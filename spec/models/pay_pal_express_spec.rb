require 'spec_helper'

describe Spree::Gateway::PayPalExpress do
  let(:gateway) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress", :environment => Rails.env) }

  context "payment purchase" do
    let(:payment) do
      payment = FactoryGirl.create(:payment, :payment_method => gateway, :amount => 10)
      payment.stub :source => mock_model(Spree::PaypalExpressCheckout, :token => 'fake_token', :payer_id => 'fake_payer_id', :update_column => true)
      payment
    end

    let(:checkout_details) do
      double('checkout details').tap do |a|
        a.stub_chain(:get_express_checkout_details_response_details, :PaymentDetails).
        and_return [{ :OrderTotal => { :currencyID => "USD", :value => "10.00" } }]
      end
    end

    let(:provider) do
      provider = double('Provider')
      provider.stub(:build_get_express_checkout_details)
      provider.stub(:get_express_checkout_details).and_return checkout_details
      gateway.stub(:provider => provider)
      provider
    end

    # Test for #11
    it "succeeds" do
      provider.should_receive(:build_do_express_checkout_payment).with({
        :DoExpressCheckoutPaymentRequestDetails => {
          :PaymentAction => "Sale",
          :Token => "fake_token",
          :PayerID => "fake_payer_id",
          :PaymentDetails => [
            { :OrderTotal => {
                :currencyID => "USD",
                :value => "10.00"
              }
            }
          ]
        }
      })
      response = double('pp_response', :success? => true)
      response.stub_chain("do_express_checkout_payment_response_details.payment_info.first.transaction_id").and_return '12345'
      provider.should_receive(:do_express_checkout_payment).and_return(response)
      lambda { payment.purchase! }.should_not raise_error
    end

    # Test for #4
    it "fails" do
      provider.should_receive(:build_do_express_checkout_payment)
      response = double('pp_response', :success? => false,
                          :errors => [double('pp_response_error', :long_message => "An error goes here.")])
      provider.should_receive(:do_express_checkout_payment).and_return(response)
      lambda { payment.purchase! }.should raise_error(Spree::Core::GatewayError, "An error goes here.")
    end
  end
end
