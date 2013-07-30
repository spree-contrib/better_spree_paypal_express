//= require store/spree_frontend

SpreePaypalExpress = {
  hidePaymentSaveAndContinueButton: function(paymentMethod) {
    if (SpreePaypalExpress.paymentMethodID && paymentMethod.value == SpreePaypalExpress.paymentMethodID) {
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
    SpreePaypalExpress.hidePaymentSaveAndContinueButton(e.target);
  });
})