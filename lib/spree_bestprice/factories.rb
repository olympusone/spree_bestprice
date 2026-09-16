FactoryBot.define do
  factory :bestprice_integration, class: Spree::Integrations::Bestprice do
    active { true }
    store { Spree::Store.default }
  end
end
