Spree::Core::Engine.add_routes do
  get '/bestprice/products.xml', to: 'bestprice#products', defaults: { format: :xml }
  get '/bestprice/products.xml.gz', to: 'bestprice#products'
end
