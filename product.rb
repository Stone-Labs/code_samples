class Product < ActiveRecord::Base

#some code here

  scope :for_estimate, -> { where(product_attributes: {active: true, estimate_included: true})
                              .joins(product_attributes: {supplier: :supplier_master})
                              .joins("LEFT OUTER JOIN product_estimates ON products.id = product_estimates.product_id AND product_estimates.region_id = suppliers.region_id")
                              .preload(:product_estimates, product_attributes: :supplier)
                              .select("products.id, products.title, supplier_masters.title as supplier_title, product_estimates.extra_orders")
                              .order('product_attributes.supplier_id ASC, products.title')}
#some code here

# Return hash with dates and product_ids that overflow limit: { date => [product_ids], date => ... }
  def self.product_ids_overflow_limit_by_date(region, product_scope, from, to)
    limits = product_scope.
        joins(:product_estimate_histories).
        with_region_attributes(region).
        where("product_attributes.with_limits" => true).
        where('product_estimate_histories.for_date' => from..to).
        where('product_estimate_histories.sent_number > 0').
        order('product_estimate_histories.for_date ASC').
        pluck('products.id, product_estimate_histories.for_date, product_estimate_histories.sent_number, product_attributes.extra_limits')

    product_ids = limits.map{ |arr| arr[0] }.uniq

    items_counts = OrderItem.joins(:order).
        where('orders.startdate' => from..to).
        where(product_id: product_ids).
        order('orders.startdate ASC').
        group('orders.startdate', 'order_items.product_id').
        count

    limits.each_with_object({}) do |(product_id, date, sent_number, extra_limits), result|
      week_day = date.strftime('%A').downcase
      extra = extra_limits[week_day].present? ? extra_limits[week_day] : 0
      limit = extra + sent_number

      items_counts[[date, product_id]] ||= 0
      
      if items_counts[[date, product_id]] >= limit
        if result[date].blank?
          result[date] = [product_id]
        else
          result[date] << product_id
        end
      end
    end
  end

#some code here

  def self.for_calendar(user, opts = {})
    joins(product_attributes: [supplier: [:supplier_master]])
      .where("suppliers.region_id = ?", user.route.region_id)
      .select([:id, :title, :price, :supplier_id, 'supplier_masters.title as supplier_title'])
      .order("product_attributes.supplier_id asc, title asc")
      .active_or_in_order(user, opts)
  end

#some code here

  def self.active_or_in_order(user, opts = {})
    scope = user.order_items.where.not(product_id: nil)

    scope = scope.where('orders.startdate' => opts[:from].to_date..opts[:to].to_date) if (opts[:from] && opts[:to])

    ordered_products_ids = scope.pluck('DISTINCT product_id')

    ordered_products_ids.present? ?
        joins(product_attributes: :supplier)
        .where("suppliers.region_id = ?", user.route.region_id)
        .where('product_attributes.active = ? OR products.id IN (?)', true, ordered_products_ids) : active(user.route.region_id)
  end
end
