//= require spree/backend

SpreePaypalExpress = {
  hideSettings: function(paymentMethod) {
    if (SpreePaypalExpress.paymentMethodID && paymentMethod.val() == SpreePaypalExpress.paymentMethodID) {
      $('.payment-method-settings').children().hide();
      $('#payment_amount').attr('disabled', 'disabled');
      $('button[type="submit"]').attr('disabled', 'disabled');
      $('#paypal-warning').show();
    } else if (SpreePaypalExpress.paymentMethodID) {
      $('.payment-method-settings').children().show();
      $('button[type=submit]').attr('disabled', '');
      $('#payment_amount').attr('disabled', '')
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