require 'spec_helper'

describe "PayPal", :js => true do
  let!(:product) { FactoryGirl.create(:product, :name => 'iPad') }
  before do
    Spree::Gateway::PayPalExpress.create!({
      :preferred_login => "paypal_api1.ryanbigg.com",
      :preferred_password => "1373587879",
      :preferred_signature => "ACOYQHq-aXKftiD4jURhihawsVSsAsaMr4qH4Tz4K17mJoa3K4M0Dvop",
      :name => "PayPal",
      :active => true,
      :environment => Rails.env
    })
    FactoryGirl.create(:shipping_method)
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
    click_button "Save and Continue"
    # Delivery step doesn't require any action
    click_button "Save and Continue"
    find("#paypal_button").click
    fill_in "cc_number", :with => "5517081817509347"
    fill_in "expdate_month", :with => "7"
    fill_in "expdate_year", :with => "18"
    fill_in "cvv2_number", :with => "123"
    fill_in "H_PhoneNumberUS", :with => "301-444-5002"
    fill_in "email-address", :with => "pp@ryanbigg.com"
    click_button "Review and Continue"
    # TODO: Maybe verify information at this step?
    click_button "Continue"
  end

  # Enter fake address information, check for an error.
  it "returns an error when it cannot match address information"

end