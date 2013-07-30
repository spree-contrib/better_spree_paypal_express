# Spree PayPal Express

## THIS IS NOT PRODUCTION READY.

This is a "re-do" of the official [spree_paypal_express][4] extension. The old extension is extremely hard to maintain and complex.

This extension purposely only uses PayPal's sandbox and never the live system. Please attempt to use this extension *only in development* and report issues.

Behind-the-scenes, this extension uses [PayPal's Merchant Ruby SDK](https://github.com/paypal/merchant-sdk-ruby).

## Installation

Add this extension to your Gemfile with this line:

    gem 'spree_paypal_express', :github => "radar/better_spree_paypal_express", :branch => "2-0-stable"

Then install it using this command:

    rails g spree_paypal_express:install

### Sandbox Setup

#### PayPal

Go to [PayPal's Developer Website](https://developer.paypal.com/), sign in with your PayPal account, click "Applications" then "Sandbox Accounts" and create a new "Business" account. Once the account is created, click on the triangle next to its email address, then "Profile". The "API Credentials" tab will provide your API credentials (probably). If this tab is blank, try refreshing the page.

You will also need a "Personal" account to test the transactions on your site. Create this in the same way, finding the account information under "Profile" as well. You may need to set a password in order to be able to log in to PayPal's sandbox for this user.

#### Spree Setup

In Spree, go to the admin backend, click "Configuration" and then "Payment Methods" and create a new payment method. Select "Spree::Gateway::PayPalExpress" as the provider, and click "Create". Enter the email address, password and signature from the "API Credentials" tab for the **Business** account on PayPal. 

### Production setup

#### PayPal

Sign in to PayPal, then click "Profile" and then (under "Account Information" on the left), click "API Access". On this page, select "Option 2" and click "View API Signature". The username, password and signature will be displayed on this screen.

If you are unable to find it, then follow [PayPal's own documentation](https://developer.paypal.com/webapps/developer/docs/classic/api/apiCredentials/).

#### Spree Setup

Same as sandbox setup, but change "Server" from "sandbox" to "live".

## Contributing

In the spirit of [free software][1], **everyone** is encouraged to help improve this project.

Here are some ways *you* can contribute:

* by using prerelease versions
* by reporting [bugs][2]
* by suggesting new features
* by writing or editing documentation
* by writing specifications
* by writing code (*no patch is too small*: fix typos, add comments, clean up inconsistent whitespace)
* by refactoring code
* by resolving [issues][2]
* by reviewing patches

Starting point:

* Fork the repo
* Clone your repo
* Run `bundle install`
* Run `bundle exec rake test_app` to create the test application in `spec/dummy`
* Make your changes
* Ensure specs pass by running `bundle exec rspec spec`
* Submit your pull request

Copyright (c) 2013 Spree Commerce and contributors, released under the [New BSD License][3]

[1]: http://www.fsf.org/licensing/essays/free-sw.html
[2]: https://github.com/spree/better_spree_paypal_express/issues
[3]: https://github.com/spree/better_spree_paypal_express/tree/master/LICENSE.md
[4]: https://github.com/spree/spree_paypal_express