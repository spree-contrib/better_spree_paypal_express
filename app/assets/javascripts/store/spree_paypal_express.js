//= require store/spree_core
//= require store/spree_promo

// Stops 'uncaught reference error' issue
Spree = {}

SpreePaypalExpress = {
  hidePaymentSaveAndContinueButton: function(paymentMethod) {
    if (SpreePaypalExpress.paymentMethodID && paymentMethod.val() == SpreePaypalExpress.paymentMethodID) {
      $('.continue').hide();
    } else {
      $('.continue').show();
    }
  }
}

$(document).ready(function() {
  checkedPaymentMethod = $('div[data-hook="checkout_payment_step"] input[type="radio"]:checked');
  SpreePaypalExpress.hidePaymentSaveAndContinueButton(checkedPaymentMethod);
  paymentMethods = $('div[data-hook="checkout_payment_step"] input[type="radio"]').click(function (e) {
    SpreePaypalExpress.hidePaymentSaveAndContinueButton($(e.target));
  });
})