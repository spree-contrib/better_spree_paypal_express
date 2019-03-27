describe "PayPal", js: true do
  let!(:product) { FactoryBot.create(:product, name: 'iPad') }
  let!(:long_max_wait) { 180 }
  let!(:medium_max_wait) { 30 }
  let!(:forced_sleep) { 15 }
  let!(:country) { FactoryBot.create(:country, name: 'United States') }
  let!(:state)   { FactoryBot.create(:state, country: country)}

  before do
    @gateway = Spree::Gateway::PayPalExpress.create!({
      preferred_login: "pp_api1.ryanbigg.com",
      preferred_password: "1383066713",
      preferred_signature: "An5ns1Kso7MWUdW4ErQKJJJ4qi4-Ar-LpzhMJL0cu8TjM8Z2e1ykVg5B",
      name: "PayPal",
      active: true
    })
    FactoryBot.create(:shipping_method)
  end

  def fill_in_billing
    fill_in :order_bill_address_attributes_firstname, with: "Test"
    fill_in :order_bill_address_attributes_lastname, with: "User"
    fill_in :order_bill_address_attributes_address1, with: "1 User Lane"
    # City, State and ZIP must all match for PayPal to be happy
    fill_in :order_bill_address_attributes_city, with: "Adamsville"
    select "United States", from: :order_bill_address_attributes_country_id
    find('#order_bill_address_attributes_state_id').find(:xpath, 'option[2]').select_option
    fill_in :order_bill_address_attributes_zipcode, with: "35005"
    fill_in :order_bill_address_attributes_phone, with: "555-123-4567"
  end

  def switch_to_paypal_login
    # If you go through a payment once in the sandbox, it remembers your preferred setting.
    # It defaults to the *wrong* setting for the first time, so we need to have this method.
    unless page.has_selector?("#login #email")
      within("#loginSection", wait: medium_max_wait) do
        click_link 'Log In'
      end
    end
  end

  def login_to_paypal
    within("#login form", wait: medium_max_wait) do
       fill_in "Email", with: "pp@spreecommerce.com"
       fill_in "Password", with: "thequickbrownfox"
       click_button "Log In"
    end
  end

  def within_transaction_cart(&block)
    find(".transactionDetails").trigger('click')
    within(".transctionCartDetails", wait: medium_max_wait) { block.call }
  end

  def add_to_cart(product)
    visit spree.root_path
    click_link product.name
    click_button 'Add To Cart'
    sleep(1)
    visit spree.cart_path
  end

  def fill_in_guest
    fill_in :order_email, with: 'test@example.com'
  end

  def click_pay_button
    # The pay button in the PayPal sandbox is troublesome: Wrap it around sleeps
    sleep(forced_sleep)
    click_button "Pay Now", wait: long_max_wait
    sleep(forced_sleep)
  end

  it "pays for an order successfully" do
    add_to_cart(product)
    click_button 'Checkout'
    fill_in_guest
    fill_in_billing
    click_button "Save and Continue"
    # Delivery step doesn't require any action
    click_button "Save and Continue"
    find("#paypal_button", wait: medium_max_wait).click

    switch_to_paypal_login
    login_to_paypal
    click_pay_button
    page.should have_content("Your order has been processed successfully", wait: long_max_wait)
    Spree::Payment.last.source.transaction_id.should_not be_blank
  end

  context "with 'Sole' solution type" do
    before do
      @gateway.preferred_solution = 'Sole'
    end

    it "passes user details to PayPal" do
      add_to_cart(product)
      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button", wait: medium_max_wait).click

      switch_to_paypal_login
      login_to_paypal
      click_pay_button
      within("#order_summary", wait: long_max_wait) do
        page.should have_selector '[data-hook=order-bill-address] .fn', text: 'Test User'
        page.should have_selector '[data-hook=order-bill-address] .adr', text: '1 User Lane'
        page.should have_selector '[data-hook=order-bill-address] .adr .local .locality', text: 'Adamsville'
        page.should have_selector '[data-hook=order-bill-address] .adr .local .postal-code', text: '35005'
        page.should have_selector '[data-hook=order-bill-address] .tel', text: '555-123-4567'
      end
    end
  end

  it "includes adjustments in PayPal summary" do
    add_to_cart(product)
    # TODO: Is there a better way to find this current order?
    order = Spree::Order.last
    Spree::Adjustment.create!(label: "$5 off", adjustable: order, order: order, amount: -5)
    Spree::Adjustment.create!(label: "$10 on", adjustable: order, order: order, amount: 10)
    visit '/cart'
    within("#cart_adjustments") do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end

    click_button 'Checkout'
    fill_in_guest
    fill_in_billing
    click_button "Save and Continue"
    # Delivery step doesn't require any action
    click_button "Save and Continue"
    find("#paypal_button", wait: medium_max_wait).click
    within('.cartContainer', wait: long_max_wait) do
      within_transaction_cart do
        page.should have_content("$5 off")
        page.should have_content("$10 on")
      end
    end

    find('#closeCart').trigger('click') # Hide cart overlay so the click isn't blocked by it
    switch_to_paypal_login
    login_to_paypal
    within('.cartContainer', wait: long_max_wait) do
      within_transaction_cart do
        page.should have_content("$5 off")
        page.should have_content("$10 on")
      end
    end

    click_pay_button
    within("[data-hook=order_details_adjustments]", wait: long_max_wait) do
      page.should have_content("$5 off")
      page.should have_content("$10 on")
    end
  end

  context "line item adjustments" do
    let(:promotion) { Spree::Promotion.create(name: "10% off") }
    before do
      calculator = Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
      action = Spree::Promotion::Actions::CreateItemAdjustments.create(calculator: calculator)
      promotion.actions << action
    end

    it "includes line item adjustments in PayPal summary" do
      add_to_cart(product)
      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      order.line_item_adjustments.count.should == 1

      visit '/cart'
      within("#cart_adjustments") do
        page.should have_content("10% off")
      end

      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button", wait: medium_max_wait).click
      within('.cartContainer', wait: long_max_wait) do
        within_transaction_cart do
          page.should have_content("10% off")
        end
      end

      find('#closeCart').trigger('click') # Hide cart overlay so the click isn't blocked by it
      switch_to_paypal_login
      login_to_paypal

      click_pay_button
      within("[data-hook=order_details_price_adjustments]", wait: long_max_wait) do
        page.should have_content("10% off")
      end
    end
  end

  # Regression test for #10
  context "will skip $0 items" do
    let!(:product2) { FactoryBot.create(:product, name: 'iPod') }

    xit do
      add_to_cart(product)
      add_to_cart(product2)
      # TODO: Is there a better way to find this current order?
      script_content = page.all('body script', visible: false).last['innerHTML']
      order_id = script_content.strip.split("\"")[1]
      order = Spree::Order.find_by(number: order_id)
      order.line_items.last.update_attribute(:price, 0)
      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button", wait: medium_max_wait).click
      within('.cartContainer', wait: long_max_wait) do
        within_transaction_cart do
          page.should have_content('iPad')
          page.should_not have_content('iPod')
        end
      end

      find('#closeCart').trigger('click') # Hide cart overlay so the click isn't blocked by it
      switch_to_paypal_login
      login_to_paypal
      within_transaction_cart do
        page.should have_content('iPad')
        page.should_not have_content('iPod')
      end

      click_pay_button
      within("#line-items", wait: long_max_wait) do
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

    xit do
      add_to_cart(product)
      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      Spree::Adjustment.create!(label: "FREE iPad ZOMG!", adjustable: order, order: order, amount: -order.line_items.last.price)
      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button", wait: medium_max_wait).click

      # find('#closeCart').trigger('click') # Hide cart overlay so the click isn't blocked by it
      switch_to_paypal_login
      login_to_paypal

      click_pay_button
      within("[data-hook=order_details_adjustments]", wait: long_max_wait) do
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
      add_to_cart(product)
      click_button 'Checkout'
      fill_in "Customer E-Mail", with: "test@example.com"
      fill_in_billing
      click_button "Save and Continue"
      # Delivery step doesn't require any action
      click_button "Save and Continue"
      find("#paypal_button", wait: medium_max_wait).click
      page.should have_content("PayPal failed. Security header is not valid")
    end
  end

  context "can process an order with Tax included prices" do
    let(:tax_rate) { create(:tax_rate, name: 'VAT Tax', amount: 0.1,
                            zone: Spree::Zone.first, included_in_price: true) }
    let(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
    let(:product3) { FactoryBot.create(:product, name: 'EU Charger', tax_category: tax_category) }
    let(:tax_string) { "VAT Tax 10.0%" }

    # Regression test for #129
    context "on countries where the Tax is applied" do

      before do
        Spree::Zone.first.update_attribute(:default_tax, true)
      end

      it do
        add_to_cart(product3)
        visit '/cart'

        within("#cart_adjustments") do
          page.should have_content("#{tax_string} (Included in Price)")
        end

        click_button 'Checkout'
        fill_in_guest
        fill_in_billing
        click_button "Save and Continue"
        # Delivery step doesn't require any action
        click_button "Save and Continue"
        find("#paypal_button", wait: medium_max_wait).click

        within('.cartContainer', wait: long_max_wait) do
          within_transaction_cart do
            # included taxes should not go on paypal
            page.should_not have_content(tax_string)
          end
        end

        find('#closeCart').trigger('click') # Hide cart overlay so the click isn't blocked by it
        switch_to_paypal_login
        login_to_paypal

        sleep(forced_sleep)
        click_button "Pay Now", wait: long_max_wait
        sleep(forced_sleep)
        page.should have_content("Your order has been processed successfully", wait: long_max_wait)
      end
    end

  end

  context "as an admin" do
    context "refunding payments" do
      before do
        stub_authorization!
        visit spree.root_path
        click_link 'iPad'
        click_button 'Add To Cart'
        click_button 'Checkout'
        within("#guest_checkout") do
          fill_in "Email", with: "test@example.com"
          click_button 'Continue'
        end
        fill_in_billing
        click_button "Save and Continue"
        # Delivery step doesn't require any action
        click_button "Save and Continue"
        find("#paypal_button", wait: medium_max_wait).click
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

      xit "can refund payments fully" do
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

      xit "can refund payments partially" do
        payment = Spree::Payment.last
        # Take a dollar off, which should cause refund type to be...
        fill_in "Amount", with: payment.amount - 1
        click_button "Refund"
        page.should have_content("PayPal refund successful")

        source = payment.source
        source.refund_transaction_id.should_not be_blank
        source.refunded_at.should_not be_blank
        source.state.should eql("refunded")
        # ... a partial refund
        source.refund_type.should eql("Partial")
      end

      xit "errors when given an invalid refund amount" do
        fill_in "Amount", with: "lol"
        click_button "Refund"
        page.should have_content("PayPal refund unsuccessful (The partial refund amount is not valid)")
      end
    end
  end
end
