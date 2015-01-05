describe Spree::PaypalController do

  # Regression tests for #55
  context "when current_order is nil" do
    before do
      controller.stub :current_order => nil
      controller.stub :current_spree_user => nil
    end

    context "express" do
      it "raises ActiveRecord::RecordNotFound" do
        expect(lambda { get :express, :use_route => :spree }).
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "confirm" do
      it "raises ActiveRecord::RecordNotFound" do
        expect(lambda { get :confirm, :use_route => :spree }).
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "cancel" do
      it "raises ActiveRecord::RecordNotFound" do
        expect(lambda { get :cancel, :use_route => :spree }).
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
