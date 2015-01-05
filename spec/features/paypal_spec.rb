describe "PayPal", :js => true do
  let!(:product) { FactoryGirl.create(:product, :name => 'iPad') }
  before do
    @gateway = Spree::Gateway::PayPalExpress.create!({
      :preferred_login => "pp_api1.ryanbigg.com",
      :preferred_password => "1383066713",
      :preferred_signature => "An5ns1Kso7MWUdW4ErQKJJJ4qi4-Ar-LpzhMJL0cu8TjM8Z2e1ykVg5B",
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
      fill_in "Phone", :with => "555-AME-RICA"
    end
  end

  def switch_to_paypal_login
    # If you go through a payment once in the sandbox, it remembers your preferred setting.
    # It defaults to the *wrong* setting for the first time, so we need to have this method.
    unless page.has_selector?("#login #email")
      find("#loadLogin").click
    end
  end

  def login_to_paypal
    within("#loginForm") do
      fill_in "Email", :with => "pp@spreecommerce.com"
      fill_in "Password", :with => "thequickbrownfox"
      click_button "Log in to PayPal"
    end
  end

  def within_transaction_cart(&block)
    find(".transactionDetails").click
    within(".transctionCartDetails") { block.call }
  end

  it "pays for an order successfully" do
    visit spree.root_path
    click_link 'iPad'
    click_button 'Add To Cart'
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
    switch_to_paypal_login
    login_to_paypal
    click_button "Pay Now"
    page.should have_content("Your order has been processed successfully")

    Spree::Payment.last.source.transaction_id.should_not be_blank
  end

  context "with 'Sole' solution type" do
    before do
      @gateway.preferred_solution = 'Sole'
    end

    it "passes user details to PayPal" do
      visit spree.root_path
      click_link 'iPad'
      click_button 'Add To Cart'
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

      login_to_paypal
      click_button "Pay Now"

      page.should have_selector '[data-hook=order-bill-address] .fn', text: 'Test User'
      page.should have_selector '[data-hook=order-bill-address] .adr', text: '1 User Lane'
      page.should have_selector '[data-hook=order-bill-address] .adr', text: 'Adamsville AL 35005'
      page.should have_selector '[data-hook=order-bill-address] .adr', text: 'United States'
      page.should have_selector '[data-hook=order-bill-address] .tel', text: '555-AME-RICA'
    end
  end

  it "includes adjustments in PayPal summary" do
    visit spree.root_path
    click_link 'iPad'
    click_button 'Add To Cart'
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
    find("#paypal_button").click

    within_transaction_cart do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end

    login_to_paypal

    within_transaction_cart do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end

    click_button "Pay Now"

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

      visit spree.root_path
      click_link 'iPad'
      click_button 'Add To Cart'
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
      find("#paypal_button").click

      within_transaction_cart do
        page.should have_content("10% off")
      end

      login_to_paypal
      click_button "Pay Now"

      within("[data-hook=order_details_price_adjustments]") do
        page.should have_content("10% off")
      end
    end
  end

  # Regression test for #10
  context "will skip $0 items" do
    let!(:product2) { FactoryGirl.create(:product, :name => 'iPod') }

    specify do
      visit spree.root_path
      click_link 'iPad'
      click_button 'Add To Cart'

      visit spree.root_path
      click_link 'iPod'
      click_button 'Add To Cart'

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
      find("#paypal_button").click

      within_transaction_cart do
        page.should have_content('iPad')
        page.should_not have_content('iPod')
      end

      login_to_paypal

      within_transaction_cart do
        page.should have_content('iPad')
        page.should_not have_content('iPod')
      end

      click_button "Pay Now"

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
      visit spree.root_path
      click_link 'iPad'
      click_button 'Add To Cart'
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
      find("#paypal_button").click

      login_to_paypal

      click_button "Pay Now"

      within("[data-hook=order_details_adjustments]") do
        page.should have_content('FREE iPad ZOMG!')
      end
    end
  end

  context "cannot process a payment with invalid gateway details" do
    before do
      @gateway.preferred_login = nil
      @gateway.save
    end

    specify do
      visit spree.root_path
      click_link 'iPad'
      click_button 'Add To Cart'
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
        visit spree.root_path
        click_link 'iPad'
        click_button 'Add To Cart'
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
        switch_to_paypal_login
        login_to_paypal
        click_button("Pay Now")
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
        source = payment.source
        source.refund_transaction_id.should_not be_blank
        source.refunded_at.should_not be_blank
        source.state.should eql("refunded")
        source.refund_type.should eql("Full")

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
