class Api::OrdersController < Api::BaseController
  before_filter :set_period_params, only: [:index, :destroy_many]

  def index
    @orders = current_user.find_orders_for_calendar(@from, @to)

    @holidays = StoreClosedDate.pluck_dates_for_period(@from, @to)
  end

  def create
    if order_params.empty?
      return respond_with_error('invalid params')
    elsif current_user.not_on_processable_route?
      return respond_with_error('unprocessable route')
    end

    @order = current_user.create_order(order_params)

    if @order.errors.blank?
      respond_with @order, status: :created
    else
      respond_with_error @order
    end
  end

  def destroy
    @order = current_user.destroy_order(params[:id])

    respond_with_error 'the order cannot be destroyed' unless @order
  end

  def destroy_many
    @orders = current_user.destroy_orders_for_period(@from, @to)

    respond_with_error 'the orders cannot be destroyed' unless @orders
  end

  def copy_for_period
    @start = Date.parse(params[:start])

    @from = [@start + 7.days, Date.current + 3.days, Date.current.beginning_of_week + 7.days].max
    @to = (@from + 4.months).end_of_week

    @copied_count = current_user.copy_orders_for_period(@start, @from, @to)
  end

  private

  def set_period_params
    @from = Date.parse(params[:from]) if params[:from]
    @to = Date.parse(params[:to]) if params[:to]
  end

  def order_params
    @order_params = begin
      active_record_order_params = {}

      if params[:order].present?
        order_params = params[:order].slice(:date, :product_ids)
        active_record_order_params[:startdate] = order_params.delete(:date)

        item_ids = order_params.delete(:product_ids)
        active_record_order_params[:order_items_attributes] = item_ids.map { |id| { product_id: id } }
      end

      active_record_order_params
    end
  end
end
