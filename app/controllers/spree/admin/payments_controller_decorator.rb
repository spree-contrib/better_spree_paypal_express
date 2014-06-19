Spree::Admin::PaymentsController.class_eval do
  def paypal_refund
    if request.get?
      if @payment.source.state == 'refunded'
        flash[:error] = Spree.t(:already_refunded, :scope => 'paypal')
        redirect_to admin_order_payment_path(@order, @payment)
      else
        @refund_amount = current_payment_refund_available
      end
    elsif request.post?
      response = @payment.payment_method.refund(@payment, params[:refund_amount].to_f)
      if response.success?
        flash[:success] = Spree.t(:refund_successful, :scope => 'paypal')
        redirect_to admin_order_payments_path(@order)
      else
        flash.now[:error] = Spree.t(:refund_unsuccessful, :scope => 'paypal') + " (#{response.errors.first.long_message})"
        render
      end
    end
  end

  private
  def current_payment_refund_available
    outstanding_balance = @order.outstanding_balance
    return outstanding_balance.abs if outstanding_balance.abs < @payment.amount && outstanding_balance < 0
    return @payment.amount - @payment.offsets_total.abs if @payment.offsets_total < 0
    @payment.amount
  end
end