module PaypalSupport
  def paypal_layout
    $paypal_layout ||= begin
                         page.find("body.pagelogin", wait: 3)
                         :new_layout
                       end
  rescue Capybara::ElementNotFound
    retries ||= 0
    if page.has_css?("body.xptSandbox")
      $paypal_layout = :old_layout
    elsif page.has_content?("Internal Server Error")
      page.reload
      retry
    else
      sleep(1)
      page.reload
      retries += 1
      retry if retries < 5
      raise "Could not determine the paypal layout"
    end
  end

  def go_to_paypal
    find("#paypal_button").click

    # Paypal keeps going back and forth with their design. The HTML is very
    # different between both.
    #
    # This changes the behavior of the specs to match the layout that Paypal
    # returns to us.
    if paypal_layout == :new_layout
      extend NewPaypal
    else
      extend OldPaypal
    end
  end

  module OldPaypal
    def login_to_paypal
        # If you go through a payment once in the sandbox, it remembers your preferred setting.
        # It defaults to the *wrong* setting for the first time, so we need to have this method.
        unless page.has_selector?("#login_email")
          find("#loadLogin").click
        end
        fill_in "login_email", :with => "pp@spreecommerce.com"
        fill_in "login_password", :with => "thequickbrownfox"
        click_button "Log In"
    end

    def within_transaction_cart(&block)
      within("#miniCart") { block.call }
    end

    def click_pay_now
      find("#continue_abovefold").click
    end

    def ship_to_heading
      "Shipping address"
    end
  end

  module NewPaypal
    def login_to_paypal
      find("#loginForm")

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

    def click_pay_now
      click_button "Pay Now"
    end

    def ship_to_heading
      "Ship to"
    end
  end
end
