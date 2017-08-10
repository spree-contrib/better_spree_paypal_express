describe Spree::PaypalController, type: :controller do
  before do
    @routes = Spree::Core::Engine.routes
  end

  # Regression tests for #55
  context "when current_order is nil" do
    before do
      allow(controller).to receive(:current_order).and_return nil
      allow(controller).to receive(:current_spree_user).and_return nil
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
        expect { get :cancel }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
