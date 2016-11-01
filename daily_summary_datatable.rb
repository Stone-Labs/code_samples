class DailySummaryDatatable < BaseDatatable

#some code here

  def get_raw_records
    scoped_products_with_filters
      .joins(orders: [user: :route])
      .joins("LEFT JOIN product_estimate_histories ON product_estimate_histories.product_id = products.id AND product_estimate_histories.for_date = '#{for_date}'")
      .select('products.*, product_estimate_histories.sent_number AS estimate, product_estimate_histories.finally_ordered AS po, count(order_items.id) as items_count')
      .where("routes.region_id = ?", region.id)
      .group('products.id', 'product_attributes.id', 'product_estimate_histories.id', 'supplier_masters.id')
  end

#some code here

end
