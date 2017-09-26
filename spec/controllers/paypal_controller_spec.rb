describe Spree::PaypalController do

  # Regression tests for #55
  context "when current_order is nil" do
    before do
      controller.stub :current_order => nil
      controller.stub :current_spree_user => nil
    end

    context "express" do
      it "raises ActiveRecord::RecordNotFound" do
        expect { get :express }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "confirm" do
      it "raises ActiveRecord::RecordNotFound" do
        expect { get :confirm }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "cancel" do
      it "raises ActiveRecord::RecordNotFound" do
        expect{ get :cancel }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
