class Spree::AdvancedReport::IncrementReport::Carts < Spree::AdvancedReport::IncrementReport
  def name
    "Carts abandoned"
  end

  def column
    "Carts"
  end

  def description
    "Total carts abandoned."
  end

  def initialize(params)
    super(params)
    self.total = 0
    self.orders.each do |order|
      date = {}
      INCREMENTS.each do |type|
        date[type] = get_bucket(type, order.created_at)
        data[type][date[type]] ||= {
          :value => 0,
          :display => get_display(type, order.created_at),
        }
      end
      order_count = order_count(order)
      INCREMENTS.each { |type| data[type][date[type]][:value] += order_count }
      self.total += order_count
    end

    generate_ruport_data
  end
end
