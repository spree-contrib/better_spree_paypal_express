//= require spree/frontend

SpreePaypalExpress = {
  updateSaveAndContinueVisibility: function() {
    if (this.isButtonHidden()) {
      $(this).trigger('hideSaveAndContinue')
    } else {
      $(this).trigger('showSaveAndContinue')
    }
  },
  isButtonHidden: function () {
    paymentMethod = this.checkedPaymentMethod();
    return (!$('#use_existing_card_yes:checked').length && SpreePaypalExpress.paymentMethodID && paymentMethod.val() == SpreePaypalExpress.paymentMethodID);
  },
  checkedPaymentMethod: function() {
    return $('div[data-hook="checkout_payment_step"] input[type="radio"][name="order[payments_attributes][][payment_method_id]"]:checked');
  },
  hideSaveAndContinue: function() {
    $("#checkout_form_payment [data-hook=buttons]").hide();
  },
  showSaveAndContinue: function() {
    $("#checkout_form_payment [data-hook=buttons]").show();
  }
}

$(document).ready(function() {
  SpreePaypalExpress.updateSaveAndContinueVisibility();
  paymentMethods = $('div[data-hook="checkout_payment_step"] input[type="radio"]').click(function (e) {
    SpreePaypalExpress.updateSaveAndContinueVisibility();
  });
})
