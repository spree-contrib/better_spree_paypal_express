//= require spree/frontend

SpreePaypalExpress = {
  hidePaymentSaveAndContinueButton: function(paymentMethod) {
    if (!$('#use_existing_card_yes:checked').length && SpreePaypalExpress.paymentMethodID && paymentMethod.val() == SpreePaypalExpress.paymentMethodID) {
      $('.continue').hide();
    } else {
      $('.continue').show();
    }
  },
  checkedPaymentMethod: function() {
    return $('div[data-hook="checkout_payment_step"] input[type="radio"][name="order[payments_attributes][][payment_method_id]"]:checked');
  }
}

$(document).ready(function() {
  SpreePaypalExpress.hidePaymentSaveAndContinueButton(SpreePaypalExpress.checkedPaymentMethod());
  paymentMethods = $('div[data-hook="checkout_payment_step"] input[type="radio"]').click(function (e) {
    SpreePaypalExpress.hidePaymentSaveAndContinueButton(SpreePaypalExpress.checkedPaymentMethod());
  });
})
