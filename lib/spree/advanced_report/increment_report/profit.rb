class Spree::AdvancedReport::IncrementReport::Profit < Spree::AdvancedReport::IncrementReport
  include ActionView::Helpers::NumberHelper

  def name
    "Profit"
  end

  def column
    "Profit"
  end

  def description
    "Total profit in orders, where profit is the sum of item quantity times item price minus item cost price"
  end

  def initialize(params)
    super(params)
    self.total = 0
    self.orders.each do |order|
      date = {}
      INCREMENTS.each do |type|
        date[type] = get_bucket(type, order.completed_at)
        data[type][date[type]] ||= {
          :value => 0, 
          :display => get_display(type, order.completed_at),
        }
      end
      profit = profit(order)
      INCREMENTS.each { |type| data[type][date[type]][:value] += profit }
      self.total += profit
    end

    generate_ruport_data

    INCREMENTS.each do |type|
      ruportdata[type].replace_column("Profit") do |r|
        number_to_currency(r["Profit"], unit: Spree::Config.currency, :delimiter => nil, :separator => '.')
      end
    end

  end

  def format_total
    number_to_currency(self.total, unit: Spree::Config.currency)
  end
end
