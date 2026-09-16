module Spree
  module Integrations
    class BestPrice < Spree::Integration
      IN_STOCK_AVAILABILITY = {
        pickup: 'Σε απόθεμα',
        delivery: 'Παράδοση σε 1-3 ημέρες'
      }.freeze

      OUT_OF_STOCK_AVAILABILITY_OPTIONS = [
        'Παράδοση σε 4-7 ημέρες',
        'Παράδοση σε 4-10 ημέρες',
        'Παράδοση σε 8-14 ημέρες',
        'Παράδοση σε 15-30 ημέρες',
        'Κατόπιν παραγγελίας',
        'Προπαραγγελία',
        'Εξαντλήθηκε'
      ].freeze

      AVAILABILITY_OPTIONS = [
        *IN_STOCK_AVAILABILITY.values,
        *OUT_OF_STOCK_AVAILABILITY_OPTIONS
      ].freeze

      preference :physical_pickup, :boolean, default: false
      preference :default_availability, :string

      def self.integration_group
        'marketing'
      end

      def self.icon_path
        'integration_icons/bestprice-logo.png'
      end
    end
  end
end
