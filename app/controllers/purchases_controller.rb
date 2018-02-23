require 'payjp'

class PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: [:new, :create]
  Payjp::api_key = ENV['PAYJP_PRIVATE_KEY']

  def index
    @purchases = current_user.purchases.order(created_at: :desc)
  end

  def new
    @purchase = Purchase.new
  end
  
  def create
    @purchase = Purchase.new(purchase_params)
    @purchase.user_id = current_user.id

    user_id = session['warden.user.user.key'][0][0]
    card = User.find(user_id).cards.first
    token = Payjp::Token.create(
        card: {
            number:    card.number,
            cvc:       card.cvc,
            exp_year:  card.exp_year,
            exp_month: card.exp_month,
        }
    )

    Payjp::Charge.create(
        amount:   @purchase.total_price,
        card:     token.id,
        currency: 'jpy'
    )
    
    if @purchase.save
      redirect_to purchases_path, notice: 'Your order was successfully placed.'
    else
      flash.now[:alert] = 'Error placing your order.'
      render :new
    end
  end
  
  private
  
    def set_event
      @event = Event.find(params[:event_id])
    end
  
    def purchase_params
      params.require(:purchase).permit(:event_id, :ticket_quantity, :total_price)
    end
end
