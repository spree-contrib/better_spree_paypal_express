require 'spec_helper'

describe "PayPal", :js => true do
  let!(:product) { FactoryGirl.create(:product, :name => 'iPad') }
  before do
    @gateway = Spree::Gateway::PayPalExpress.create!({
      :preferred_login => "pp_api1.ryanbigg.com",
      :preferred_password => "1383066713",
      :preferred_signature => "An5ns1Kso7MWUdW4ErQKJJJ4qi4-Ar-LpzhMJL0cu8TjM8Z2e1ykVg5B",
      :preferred_solution => "Mark",
      :preferred_address_override => '0',
      :preferred_no_shipping => '1',
      :preferred_req_confirmed_address => '0',
      :name => "PayPal",
      :active => true,
      :environment => Rails.env
    })
    FactoryGirl.create(:shipping_method)
  end

  def fill_in_billing
    within("#billing") do
      fill_in "First Name", :with => "Test"
      fill_in "Last Name", :with => "User"
      fill_in "Street Address", :with => "1 User Lane"
      # City, State and ZIP must all match for PayPal to be happy
      fill_in "City", :with => "Adamsville"
      select "United States of America", :from => "order_bill_address_attributes_country_id"
      select "Alabama", :from => "order_bill_address_attributes_state_id"
      fill_in "Zip", :with => "35005"
      fill_in "Phone", :with => "555-123-4567"
    end
  end

  def fill_in_shipping
    uncheck("order[use_billing]")
    within("#shipping") do
      fill_in "First Name", :with => "Test"
      fill_in "Last Name", :with => "User"
      fill_in "Street Address", :with => "2 User Lane"
      # City, State and ZIP must all match for PayPal to be happy
      fill_in "City", :with => "Adamsville"
      select "United States of America", :from => "order_ship_address_attributes_country_id"
      select "Alabama", :from => "order_ship_address_attributes_state_id"
      fill_in "Zip", :with => "35005"
      fill_in "Phone", :with => "555-123-4567"
    end
  end


  def add_product_to_cart(product)
    visit spree.root_path
    click_link product
    click_button 'Add To Cart'
  end

  it "pays for an order successfully" do
    add_product_to_cart 'iPad'
    click_button 'Checkout'
    within("#guest_checkout") do
      fill_in "Email", :with => "test@example.com"
      click_button 'Continue'
    end
    fill_in_billing
    click_button "Save and Continue"
    # Delivery step doesn't require any action
    click_button "Save and Continue"
    go_to_paypal
    login_to_paypal
    click_pay_now
    page.should have_content("Your order has been processed successfully")

    Spree::Payment.last.source.transaction_id.should_not be_blank
  end

  context "with 'Sole' solution type" do
    before do
      @gateway.preferred_solution = 'Sole'
    end

    it "passes user details to PayPal" do
      add_product_to_cart('iPad')
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", :with => "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      login_to_paypal
      click_pay_now
      page.should have_selector '[data-hook=order-bill-address] .fn', text: 'Test User'
      page.should have_selector '[data-hook=order-bill-address] .adr', text: '1 User Lane'
      page.should have_selector '[data-hook=order-bill-address] .adr', text: 'Adamsville AL 35005'
      page.should have_selector '[data-hook=order-bill-address] .adr', text: 'United States'
      page.should have_selector '[data-hook=order-bill-address] .tel', text: '555-123-4567'
    end
  end

  it "includes adjustments in PayPal summary" do
    add_product_to_cart('iPad')
    # TODO: Is there a better way to find this current order?
    order = Spree::Order.last
    order.adjustments.create!(:amount => -5, :label => "$5 off")
    order.adjustments.create!(:amount => 10, :label => "$10 on")
    visit '/cart'
    within("#cart_adjustments") do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end
    click_button 'Checkout'
    within("#guest_checkout") do
      fill_in "Email", :with => "test@example.com"
      click_button 'Continue'
    end
    fill_in_billing
    click_button "Save and Continue"
    # Delivery step doesn't require any action
    click_button "Save and Continue"

    go_to_paypal

    within_transaction_cart do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end

    login_to_paypal

    within_transaction_cart do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end

    click_pay_now

    within("[data-hook=order_details_adjustments]") do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end
  end

  context "line item adjustments" do
    let(:promotion) { Spree::Promotion.create(name: "10% off") }
    before do
      calculator = Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
      action = Spree::Promotion::Actions::CreateItemAdjustments.create(:calculator => calculator)
      promotion.actions << action
    end

    it "includes line item adjustments in PayPal summary" do
      add_product_to_cart('iPad')
      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      order.line_item_adjustments.count.should == 1

      visit '/cart'
      within("#cart_adjustments") do
        page.should have_content("10% off")
      end
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", :with => "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      within_transaction_cart do
        page.should have_content("10% off")
      end

      login_to_paypal
      click_pay_now

      within("[data-hook=order_details_price_adjustments]") do
        page.should have_content("10% off")
      end
    end
  end


  # Regression test for #10
  context "will skip $0 items" do
    let!(:product2) { FactoryGirl.create(:product, :name => 'iPod') }

    specify do
      add_product_to_cart('iPad')
      add_product_to_cart('iPod')

      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      order.line_items.last.update_attribute(:price, 0)
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", :with => "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      within_transaction_cart do
        page.should have_content('iPad')
        page.should_not have_content('iPod')
      end

      login_to_paypal

      within_transaction_cart do
        page.should have_content('iPad')
        page.should_not have_content('iPod')
      end

      click_pay_now

      within("#line-items") do
        page.should have_content('iPad')
        page.should have_content('iPod')
      end
    end
  end

  context "can process an order with $0 item total" do
    before do
      # If we didn't do this then the order would be free and skip payment altogether
      calculator = Spree::ShippingMethod.first.calculator
      calculator.preferred_amount = 10
      calculator.save
    end

    specify do
      add_product_to_cart('iPad')
      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      order.adjustments.create!(:amount => -order.line_items.last.price, :label => "FREE iPad ZOMG!")
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", :with => "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      login_to_paypal

      click_pay_now

      within("[data-hook=order_details_adjustments]") do
        page.should have_content('FREE iPad ZOMG!')
      end
    end
  end

  shared_examples_for :no_shipping do
    it "displays the shipping address on file on the paypal page" do
      add_product_to_cart('iPad')
      click_button 'Checkout'
      within('#guest_checkout') do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      fill_in_shipping

      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"


      go_to_paypal

      login_to_paypal

      page.should have_content(ship_to_heading)

      click_pay_now

      page.should have_content("Your order has been processed successfully")
    end
  end

  context "displays the shipping address on the paypal page" do
    before do
      @gateway.preferred_no_shipping = '0'
      @gateway.save
    end

    it_behaves_like :no_shipping
  end

  shared_examples_for :no_shipping_displayed do
    it "does not show the address by default" do
      add_product_to_cart('iPad')
      click_button 'Checkout'
      within('#guest_checkout') do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      fill_in_shipping

      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      login_to_paypal

      page.should have_no_content(ship_to_heading)

      click_pay_now

      page.should have_content("Your order has been processed successfully")
    end
  end

  context "requiring confirmed shipping address" do
    before do
      @gateway.preferred_req_confirmed_address = '1'
      @gateway.save
    end

    it_behaves_like :no_shipping_displayed

    it "overrides the shipping address on the order with the confirmed one" do
      maryland = FactoryGirl.create(:state, name: "Maryland", abbr: "MD")

      add_product_to_cart('iPad')
      click_button 'Checkout'
      within('#guest_checkout') do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      fill_in_shipping

      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      login_to_paypal

      page.should have_no_content(ship_to_heading)

      click_pay_now

      page.should have_content("Your order has been processed successfully")

      order = Spree::Order.last
      express_checkout = order.payments.last.source

      address = express_checkout.address
      address.should_not be_nil

      address.address1.should eq("Suite 510")
      address.address2.should eq("7735 Old Georgetown Road")
      address.city.should eq("Bethesda")
      address.state.should eq(maryland)
    end
  end

  context "displays the shipping address on the paypal page when none is passed" do
    before do
      @gateway.preferred_no_shipping = '2'
      @gateway.save
    end

    it_behaves_like :no_shipping
  end

  context "default no shipping option" do
    it_behaves_like :no_shipping_displayed
  end

  context "shipping address override" do
    before do
      @gateway.preferred_no_shipping = '0'
      @gateway.preferred_address_override = '1'
      @gateway.save
    end

    it "shipping address from order" do
      add_product_to_cart('iPad')
      click_button 'Checkout'
      within('#guest_checkout') do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      fill_in_shipping

      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      login_to_paypal

      page.should have_content("2 User Lane")

      click_pay_now

      page.should have_content("Your order has been processed successfully")
    end

    it "billing address from order" do
      add_product_to_cart('iPad')
      click_button 'Checkout'
      within('#guest_checkout') do
        fill_in "Email", with: "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing

      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"

      go_to_paypal

      login_to_paypal

      page.should have_content("1 User Lane")

      click_pay_now

      page.should have_content("Your order has been processed successfully")
    end
  end

  context "cannot process a payment with invalid gateway details" do
    before do
      @gateway.preferred_login = nil
      @gateway.save
    end

    specify do
      add_product_to_cart('iPad')
      click_button 'Checkout'
      within("#guest_checkout") do
        fill_in "Email", :with => "test@example.com"
        click_button 'Continue'
      end
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button").click
      page.should have_content("PayPal failed. Security header is not valid")
    end
  end

  context "as an admin" do
    stub_authorization!

    context "refunding payments" do
      before do
        add_product_to_cart('iPad')
        click_button 'Checkout'
        within("#guest_checkout") do
          fill_in "Email", :with => "test@example.com"
          click_button 'Continue'
        end
        fill_in_billing
        click_button "Save and Continue"
        # Delivery step doesn't require any action
        click_button "Save and Continue"

        go_to_paypal
        login_to_paypal
        click_pay_now
        page.should have_content("Your order has been processed successfully")

        visit '/admin'
        click_link Spree::Order.last.number
        click_link "Payments"
        find("#content").find("table").first("a").click # this clicks the first payment
        click_link "Refund"
      end

      it "can refund payments fully" do
        click_button "Refund"
        page.should have_content("PayPal refund successful")

        payment = Spree::Payment.last
        paypal_checkout = payment.source.source
        paypal_checkout.refund_transaction_id.should_not be_blank
        paypal_checkout.refunded_at.should_not be_blank
        paypal_checkout.state.should eql("refunded")
        paypal_checkout.refund_type.should eql("Full")

        # regression test for #82
        within("table") do
          page.should have_content(payment.display_amount.to_html)
        end
      end

      it "can refund payments partially" do
        payment = Spree::Payment.last
        # Take a dollar off, which should cause refund type to be...
        fill_in "Amount", :with => payment.amount - 1
        click_button "Refund"
        page.should have_content("PayPal refund successful")

        source = payment.source
        source.refund_transaction_id.should_not be_blank
        source.refunded_at.should_not be_blank
        source.state.should eql("refunded")
        # ... a partial refund
        source.refund_type.should eql("Partial")
      end

      it "errors when given an invalid refund amount" do
        fill_in "Amount", :with => "lol"
        click_button "Refund"
        page.should have_content("PayPal refund unsuccessful (The partial refund amount is not valid)")
      end
    end
  end
end
