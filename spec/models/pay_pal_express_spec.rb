describe Spree::Gateway::PayPalExpress do
  let(:gateway) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress") }

  context "payment purchase" do
    let(:payment) do
      payment = FactoryGirl.create(:payment, :payment_method => gateway, :amount => 10)
      payment.stub :source => mock_model(Spree::PaypalExpressCheckout, :token => 'fake_token', :payer_id => 'fake_payer_id', :update_column => true)
      payment
    end

    let(:provider) do
      provider = double('Provider')
      gateway.stub(:provider => provider)
      provider
    end

    before do
      provider.should_receive(:build_get_express_checkout_details).with({
        :Token => 'fake_token'
      }).and_return(pp_details_request = double)

      pp_details_response = double(:get_express_checkout_details_response_details =>
        double(:PaymentDetails => {
          :OrderTotal => {
            :currencyID => "USD",
            :value => "10.00"
          }
        }))

      provider.should_receive(:get_express_checkout_details).
        with(pp_details_request).
        and_return(pp_details_response)

      provider.should_receive(:build_do_express_checkout_payment).with({
        :DoExpressCheckoutPaymentRequestDetails => {
          :PaymentAction => "Sale",
          :Token => "fake_token",
          :PayerID => "fake_payer_id",
          :PaymentDetails => pp_details_response.get_express_checkout_details_response_details.PaymentDetails
        }
      })
    end

    # Test for #11
    it "succeeds" do
      response = double('pp_response', :success? => true)
      response.stub_chain("do_express_checkout_payment_response_details.payment_info.first.transaction_id").and_return '12345'
      provider.should_receive(:do_express_checkout_payment).and_return(response)
      lambda { payment.purchase! }.should_not raise_error
    end

    # Test for #4
    it "fails" do
      response = double('pp_response', :success? => false,
                          :errors => [double('pp_response_error', :long_message => "An error goes here.")])
      provider.should_receive(:do_express_checkout_payment).and_return(response)
      lambda { payment.purchase! }.should raise_error(Spree::Core::GatewayError, "An error goes here.")
    end
  end
end
