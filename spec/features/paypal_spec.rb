describe 'PayPal', js: true do
  let!(:product) { create(:product, name: 'iPad') }
  let!(:country) { create(:country, name: 'United States') }
  let!(:state)   { create(:state, country: country)}

  before do
    @gateway = Spree::Gateway::PayPalExpress.create!({
      preferred_login: 'pp_api1.ryanbigg.com',
      preferred_password: '1383066713',
      preferred_signature: 'An5ns1Kso7MWUdW4ErQKJJJ4qi4-Ar-LpzhMJL0cu8TjM8Z2e1ykVg5B',
      name: 'PayPal',
      active: true
    })
    create(:shipping_method)
  end

  def fill_in_billing
    fill_in :order_bill_address_attributes_firstname, with: 'Test'
    fill_in :order_bill_address_attributes_lastname, with: 'User'
    fill_in :order_bill_address_attributes_address1, with: '1 User Lane'
    fill_in :order_bill_address_attributes_city, with: 'Adamsville'
    select 'United States', from: :order_bill_address_attributes_country_id
    find('#order_bill_address_attributes_state_id').find(:xpath, 'option[2]').select_option
    fill_in :order_bill_address_attributes_zipcode, with: '35005'
    fill_in :order_bill_address_attributes_phone, with: '555-123-4567'
  end

  def switch_to_paypal_login
    unless page.has_selector?('#login #email')
      if page.has_css?('.changeLanguage') 
        wait_for { !page.has_css?('div#preloaderSpinner') }
        find('.changeLanguage').click
        find_all('a', text: 'English')[0].click
      end
      wait_for { page.has_link?(text: 'Log In') }
      wait_for { !page.has_css?('div.spinWrap') }
      click_link 'Log In'
    end
  end

  def login_to_paypal
    wait_for { page.has_text?('Pay with PayPal') }
    fill_in 'email', with: 'pp@spreecommerce.com'
    fill_in 'password', with: 'thequickbrownfox'
    click_button 'btnLogin'
  end

  def within_transaction_cart(container_class, expected_texts, unexpected_texts)
    wait_for { page.has_css?('span#transactionCart') }
    wait_for { !page.has_css?('div#preloaderSpinner') }
    wait_for { !page.has_css?('div#spinner') }
    find('span#transactionCart').click

    within(container_class) do
      expected_texts.each do |expected_text|
        expect(page).to have_content(expected_text)
      end

      unexpected_texts.each do |unexpected_text|
        expect(page).not_to have_content(unexpected_text)
      end
    end

    find('#closeCart').click
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

  def click_pay_now_button
    wait_for { page.has_button?('Pay Now') }
    wait_for { page.has_css?('div#button') }
    click_button 'Pay Now'
  end

  def click_paypal_button
    wait_for { page.has_link?(id: 'paypal_button') }
    find('#paypal_button').click
  end

  def stay_logged_in_for_faster_checkout
    if page.has_text?('Stay logged in for faster checkout')
      click_link 'Not now'
    end
  end

  def expect_successfully_processed_order
    wait_for { page.has_css?('div.alert-notice') }
    order_number = Spree::Order.last.number
    expect(page).to have_current_path("/orders/#{order_number}")
    expect(page).to have_content('Your order has been processed successfully')
  end

  it 'pays for an order successfully' do
    add_to_cart(product)
    click_button 'Checkout'
    fill_in_guest
    fill_in_billing
    click_button 'Save and Continue'
    click_button 'Save and Continue'

    click_paypal_button
    switch_to_paypal_login
    login_to_paypal
    stay_logged_in_for_faster_checkout
    click_pay_now_button
    expect_successfully_processed_order
    expect(Spree::Payment.last.source.transaction_id).not_to be_empty
  end

  context "with 'Sole' solution type" do
    before do
      @gateway.preferred_solution = 'Sole'
    end

    it 'passes user details to PayPal' do
      add_to_cart(product)
      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button 'Save and Continue'
      click_button 'Save and Continue'

      click_paypal_button
      switch_to_paypal_login
      login_to_paypal
      stay_logged_in_for_faster_checkout
      click_pay_now_button
      wait_for { page.has_text?('555-123-4567') }
      within('#order_summary') do
        expect(page).to have_selector '[data-hook=order-bill-address] .fn', text: 'Test User'
        expect(page).to have_selector '[data-hook=order-bill-address] .adr', text: '1 User Lane'
        expect(page).to have_selector '[data-hook=order-bill-address] .adr .local .locality', text: 'Adamsville'
        expect(page).to have_selector '[data-hook=order-bill-address] .adr .local .postal-code', text: '35005'
        expect(page).to have_selector '[data-hook=order-bill-address] .tel', text: '555-123-4567'
      end
    end
  end

  it 'includes adjustments in PayPal summary' do
    add_to_cart(product)
    # TODO: Is there a better way to find this current order?
    order = Spree::Order.last
    Spree::Adjustment.create!(label: '$5 off', adjustable: order, order: order, amount: -5)
    Spree::Adjustment.create!(label: '$10 on', adjustable: order, order: order, amount: 10)
    visit '/cart'
    within('#cart_adjustments') do
      expect(page).to have_content('$5 off')
      expect(page).to have_content('$10 on')
    end

    click_button 'Checkout'
    fill_in_guest
    fill_in_billing
    click_button 'Save and Continue'
    click_button 'Save and Continue'

    click_paypal_button
    within_transaction_cart('.cartContainer', ['$5 off', '$10 on'], [])
    switch_to_paypal_login
    login_to_paypal
    stay_logged_in_for_faster_checkout
    within_transaction_cart('.cartContainer', ['$5 off', '$10 on'], [])
    click_pay_now_button
    wait_for { page.has_css?('[data-hook=order_details_adjustments]') }
    within('[data-hook=order_details_adjustments]') do
      expect(page).to have_content('$5 off')
      expect(page).to have_content('$10 on')
    end
  end

  context 'line item adjustments' do
    let(:promotion) { Spree::Promotion.create(name: '10% off') }
    before do
      calculator = Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
      action = Spree::Promotion::Actions::CreateItemAdjustments.create(calculator: calculator)
      promotion.actions << action
    end

    it 'includes line item adjustments in PayPal summary' do
      add_to_cart(product)
      # TODO: Is there a better way to find this current order?
      order = Spree::Order.last
      expect(order.line_item_adjustments.count).to eq 1

      visit '/cart'
      within('#cart_adjustments') do
        expect(page).to have_content('10% off')
      end

      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button 'Save and Continue'
      click_button 'Save and Continue'

      click_paypal_button
      within_transaction_cart('.cartContainer', ['10% off'], [])
      switch_to_paypal_login
      login_to_paypal
      stay_logged_in_for_faster_checkout
      click_pay_now_button
      wait_for { page.has_css?('strong', text: '10% off') }
      within('#price-adjustments') do
        expect(page).to have_content('10% off')
      end
    end
  end

  # Regression test for #10
  context 'will skip $0 items' do
    let!(:product2) { create(:product, name: 'iPod') }

    xit do
      add_to_cart(product)
      add_to_cart(product2)
      # TODO: Is there a better way to find this current order?
      script_content = page.all('body script', visible: false).last['innerHTML']
      order_id = script_content.strip.split('\"')[1]
      order = Spree::Order.find_by(number: order_id)
      order.line_items.last.update_attribute(:price, 0)
      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button 'Save and Continue'
      click_button 'Save and Continue'

      click_paypal_button
      
      within_transaction_cart('.cartContainer', ['iPad'], ['iPod'])
      wait_for { page.has_css?('.transactionDetails') }
      switch_to_paypal_login
      login_to_paypal
      stay_logged_in_for_faster_checkout
      within_transaction_cart('.transctionCartDetails', ['iPad'], ['iPod'])
      click_pay_now_button
      wait_for { page.has_text?('iPad') }
      within('#line-items') do
        expect(page).to have_content('iPad')
        expect(page).to have_content('iPod')
      end
    end
  end

  context 'can process an order with $0 item total' do
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
      Spree::Adjustment.create!(label: 'FREE iPad ZOMG!', adjustable: order, order: order, amount: -order.line_items.last.price)
      click_button 'Checkout'
      fill_in_guest
      fill_in_billing
      click_button 'Save and Continue'
      click_button 'Save and Continue'

      click_paypal_button
      switch_to_paypal_login
      login_to_paypal
      stay_logged_in_for_faster_checkout
      click_pay_now_button
      wait_for { page.has_text?('FREE iPad ZOMG!') }
      within('[data-hook=order_details_adjustments]') do
        expect(page).to have_content('FREE iPad ZOMG!')
      end
    end
  end

  context 'cannot process a payment with invalid gateway details' do
    before do
      @gateway.preferred_login = nil
      @gateway.save
    end

    specify do
      add_to_cart(product)
      click_button 'Checkout'
      fill_in 'Customer E-Mail', with: 'test@example.com'
      fill_in_billing
      click_button 'Save and Continue'
      click_button 'Save and Continue'

      click_paypal_button
      expect(page).to have_content('PayPal failed. Security header is not valid')
    end
  end

  context 'can process an order with Tax included prices' do
    let(:tax_rate) { create(:tax_rate, name: 'VAT Tax', amount: 0.1,
                            zone: Spree::Zone.first, included_in_price: true) }
    let(:tax_category) { create(:tax_category, tax_rates: [tax_rate]) }
    let(:product3) { create(:product, name: 'EU Charger', tax_category: tax_category) }
    let(:tax_string) { 'VAT Tax 10.0%' }

    # Regression test for #129
    context 'on countries where the Tax is applied' do
      before { Spree::Zone.first.update_attribute(:default_tax, true) }
    end
  end

  context 'as an admin' do
    context 'refunding payments' do
      before do
        stub_authorization!
        visit spree.root_path
        click_link 'iPad'
        click_button 'Add To Cart'
        click_button 'Checkout'
        within('#guest_checkout') do
          fill_in 'Email', with: 'test@example.com'
          click_button 'Continue'
        end
        fill_in_billing
        click_button 'Save and Continue'
        click_button 'Save and Continue'

        click_paypal_button
        switch_to_paypal_login
        login_to_paypal
        stay_logged_in_for_faster_checkout
        click_pay_now_button
        expect_successfully_processed_order

        visit '/admin'
        click_link Spree::Order.last.number
        click_link 'Payments'
        find('#content').find('table').first('a').click # this clicks the first payment
        click_link 'Refund'
      end

      xit 'can refund payments fully' do
        click_button 'Refund'
        expect(page).to have_content('PayPal refund successful')

        payment = Spree::Payment.last
        paypal_checkout = payment.source.source
        expect(paypal_checkout.refund_transaction_id).to_not be_blank
        expect(paypal_checkout.refunded_at).to_not be_blank
        expect(paypal_checkout.state).to eql('refunded')
        expect(paypal_checkout.refund_type).to eql('Full')

        # regression test for #82
        within('table') do
          expect(page).to have_content(payment.display_amount.to_html)
        end
      end

      xit 'can refund payments partially' do
        payment = Spree::Payment.last
        # Take a dollar off, which should cause refund type to be...
        fill_in 'Amount', with: payment.amount - 1
        click_button 'Refund'
        expect(page).to have_content('PayPal refund successful')

        source = payment.source
        expect(source.refund_transaction_id).to_not be_blank
        expect(source.refunded_at).to_not be_blank
        expect(source.state).to eql('refunded')
        # ... a partial refund
        expect(source.refund_type).to eql('Partial')
      end

      xit 'errors when given an invalid refund amount' do
        fill_in 'Amount', with: 'lol'
        click_button 'Refund'
        expect(page).to have_content('PayPal refund unsuccessful (The partial refund amount is not valid)')
      end
    end
  end
end
