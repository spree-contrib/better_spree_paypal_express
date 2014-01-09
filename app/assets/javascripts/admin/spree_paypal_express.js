//= require store/spree_core
//= require store/spree_promo

SpreePaypalExpress = {
  hideSettings: function(paymentMethod) {
    if (SpreePaypalExpress.paymentMethodID && paymentMethod.val() == SpreePaypalExpress.paymentMethodID) {
      $('.payment-method-settings').children().hide();
      $('#payment_amount').prop('disabled', 'disabled');
      $('button[type="submit"]').prop('disabled', 'disabled');
      $('#paypal-warning').show();
    } else if (SpreePaypalExpress.paymentMethodID) {
      $('.payment-method-settings').children().show();
      $('button[type=submit]').prop('disabled', '');
      $('#payment_amount').prop('disabled', '')
      $('#paypal-warning').hide();
    }
  }
}

$(document).ready(function() {
  checkedPaymentMethod = $('#payment-methods input[type="radio"]:checked');
  SpreePaypalExpress.hideSettings(checkedPaymentMethod);
  paymentMethods = $('#payment-methods input[type="radio"]').click(function (e) {
    SpreePaypalExpress.hideSettings($(e.target));
  });
})
