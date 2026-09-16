Rails.application.config.after_initialize do
  Spree.integrations << Spree::Integrations::BestPrice

  Spree::PermittedAttributes.product_attributes.push(:bestprice_availability)

  Rails.application.config.spree_admin.product_form_partials << 'spree/admin/products/bestprice_availability'
end
