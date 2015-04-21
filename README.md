# Spree PayPal Express

[![Build Status](https://travis-ci.org/spree-contrib/better_spree_paypal_express.svg?branch=3-0-stable)](https://travis-ci.org/spree-contrib/better_spree_paypal_express)

This is a "re-do" of the official [spree_paypal_express][4] extension. The old extension is extremely hard to maintain and complex.

Behind-the-scenes, this extension uses [PayPal's Merchant Ruby SDK](https://github.com/paypal/merchant-sdk-ruby).

## Installation

1. Add this extension to your Gemfile with this line:

        gem 'spree_paypal_express', github: 'spree-contrib/better_spree_paypal_express', branch: '3-0-stable'

The `branch` option is important: it must match the version of Spree you're using. Use 3-0-stable if you're using Spree 3-0-stable or any 3.0.x version.

2. Install the gem using Bundler:

        bundle install

3. Copy & run migrations

        bundle exec rails g spree_paypal_express:install

4. Restart your server

If your server was running, restart it so that it can find the assets properly.

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

## Configuration

The PayPal Express Checkout has [no less than 4.5 billion configuration options](https://github.com/paypal/merchant-sdk-ruby/blob/1d65e598d2f9f200f85c6b3338d4293dbed576d8/lib/paypal-sdk/merchant/data_types.rb#L830-L959).

This Spree extension supports *some* of those. If your favourite is not here, then please submit an issue about it, or better still a patch to add it in.

### Solution Type

Determines whether or not a user needs a PayPal account to check out.

```ruby
payment_method.preferred_solution_type = "Mark"
# or
payment_method.preferred_solution_type = "Sole"
```

"Mark" if you do want users to have a paypal account, "Sole" otherwise.

### Landing Page

Determines which page to show users once they're redirected to PayPal.

```ruby
payment_method.preferred_landing_page = "Login"
# or
payment_method.preferred_landing_page = "Billing"
```

"Login" will show the users the login form for PayPal, and "Billing" will show them a form where they can enter their credit card data and possibly sign up for a PayPal account (depending on the Solution Type setting above).

### Logo

Determines what logo, if any, to display at the top left of the PayPal express checkout:

```ruby
payment_method.preferred_logourl = 'http://yoursite.com/images/checkout.jpg'
```

**Must** be an absolute path to the image.

## Caveats

*Caveat venditor*

Paypal will refuse any order with a zero cost item.
Any such item will be skipped and not displayed.

PayPal will also refuse any order where item total (before taxes and shipping costs) is zero.
In this case the PayPal checkout page will simply display "Current order".

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

Copyright (c) 2013-2015 Spree Commerce and contributors, released under the [New BSD License][3]

[1]: http://www.fsf.org/licensing/essays/free-sw.html
[2]: https://github.com/spree/better_spree_paypal_express/issues
[3]: https://github.com/spree/better_spree_paypal_express/tree/master/LICENSE.md
[4]: https://github.com/spree/spree_paypal_express
