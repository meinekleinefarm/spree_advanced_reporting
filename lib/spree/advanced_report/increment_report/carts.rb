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
    self.params = params
    self.data = {}
    self.ruportdata = {}
    self.unfiltered_params = params[:search].blank? ? {} : params[:search].clone

    params[:search] ||= {}
    if params[:search][:created_at_gt].blank?
      if (Spree::Order.count > 0) && Spree::Order.minimum(:created_at)
        params[:search][:created_at_gt] = Spree::Order.minimum(:created_at).beginning_of_day
      end
    else
      params[:search][:created_at_gt] = Time.zone.parse(params[:search][:created_at_gt]).beginning_of_day rescue ""
    end
    if params[:search][:created_at_lt].blank?
      if (Spree::Order.count > 0) && Spree::Order.maximum(:created_at)
        params[:search][:created_at_lt] = Spree::Order.maximum(:created_at).end_of_day
      end
    else
      params[:search][:created_at_lt] = Time.zone.parse(params[:search][:created_at_lt]).end_of_day rescue ""
    end

    params[:search][:state_not_eq] = 'canceled'

    search = Spree::Order.search(params[:search])
    # self.orders = search.state_does_not_equal('canceled')
    self.orders = search.result

    self.product_in_taxon = true
    if params[:advanced_reporting]
      if params[:advanced_reporting][:taxon_id] && params[:advanced_reporting][:taxon_id] != ''
        self.taxon = Spree::Taxon.find(params[:advanced_reporting][:taxon_id])
      end
      if params[:advanced_reporting][:product_id] && params[:advanced_reporting][:product_id] != ''
        self.product = Spree::Product.find(params[:advanced_reporting][:product_id])
      end
    end
    if self.taxon && self.product && !self.product.taxons.include?(self.taxon)
      self.product_in_taxon = false
    end

    if self.product
      self.product_text = "Product: #{self.product.name}<br />"
    end
    if self.taxon
      self.taxon_text = "Taxon: #{self.taxon.name}<br />"
    end

    # Above searchlogic date settings
    self.date_text = "Date Range:"
    if self.unfiltered_params
      if self.unfiltered_params[:created_at_gt] != '' && self.unfiltered_params[:created_at_lt] != ''
        self.date_text += " From #{self.unfiltered_params[:created_at_gt]} to #{self.unfiltered_params[:created_at_lt]}"
      elsif self.unfiltered_params[:created_at_gt] != ''
        self.date_text += " After #{self.unfiltered_params[:created_at_gt]}"
      elsif self.unfiltered_params[:created_at_lt] != ''
        self.date_text += " Before #{self.unfiltered_params[:created_at_lt]}"
      else
        self.date_text += " All"
      end
    else
      self.date_text += " All"
    end

    self.increments = INCREMENTS
    self.ruportdata = INCREMENTS.inject({}) { |h, inc| h[inc] = Table(%w[key display value]); h }
    self.data = INCREMENTS.inject({}) { |h, inc| h[inc] = {}; h }

    self.dates = {
      :daily => {
        :date_bucket => "%F",
        :date_display => "%m-%d-%Y",
        :header_display => 'Daily',
      },
      :weekly => {
        :header_display => 'Weekly'
      },
      :monthly => {
        :date_bucket => "%Y-%m",
        :date_display => "%B %Y",
        :header_display => 'Monthly',
      },
      :quarterly => {
        :header_display => 'Quarterly'
      },
      :yearly => {
        :date_bucket => "%Y",
        :date_display => "%Y",
        :header_display => 'Yearly',
      }
    }

    self.total = 0
    self.orders.incomplete.each do |order|
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
