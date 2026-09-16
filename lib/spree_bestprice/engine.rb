module SpreeBestPrice
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_bestprice'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'spree_bestprice.environment', before: :load_config_initializers do |_app|
      SpreeBestPrice::Config = SpreeBestPrice::Configuration.new
    end

    initializer 'spree_bestprice.assets' do |app|
      app.config.assets.precompile += %w[spree_bestprice_manifest]
    end

    initializer 'spree_bestprice.importmap', before: 'importmap' do |app|
      app.config.importmap.paths << root.join('config/importmap.rb')
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
