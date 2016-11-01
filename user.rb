class User < ActiveRecord::Base

# Some code here

  scope :in_regions, ->(regions) {joins("LEFT OUTER JOIN regions_users ON regions_users.user_id = users.id").where(regions_users: {region_id: regions})}

# Some code here

  def self.with_orders_info
    select("users.*, routes.number as route_number, count(distinct orders.id) as orders_count, count(order_items.id) as order_items_count, last_order.last_date").
        joins("LEFT OUTER JOIN routes ON routes.id = users.route_id").
        joins("LEFT OUTER JOIN orders ON orders.user_id = users.id LEFT OUTER JOIN order_items ON order_items.order_id = orders.id AND order_items.product_id IS NOT NULL").
        joins("LEFT OUTER JOIN (SELECT orders.user_id as user_id, MAX(orders.startdate) as last_date FROM orders INNER JOIN order_items ON order_items.order_id = orders.id AND order_items.product_id IS NOT NULL GROUP BY orders.user_id) AS last_order ON users.id=last_order.user_id").
        group("users.id, last_order.last_date, routes.number")
  end

# Some code here

  def ordered_products_ids_by_date(from, to)
    ordered_products_ids_by_date_array = orders.joins(:order_items).
        where('orders.startdate' => from..to).
        order(startdate: :asc).
        group('orders.startdate').
        pluck('orders.startdate','array_agg(order_items.product_id)')

    ordered_products_ids_by_date_array.each_with_object({}){ |arr, res| res[arr[0]] = arr[1] }
  end

# Some code here

end