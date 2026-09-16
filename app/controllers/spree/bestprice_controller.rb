module Spree
  class BestpriceController < StoreController
    include BaseHelper
    include StorefrontHelper

    before_action :ensure_feed_enabled

    def products
      respond_to do |format|
        format.xml do
          render template: 'spree_bestprice/products', formats: [:xml]
        end
        format.gzip do
          gz_xml = ActiveSupport::Gzip.compress(render_to_string(template: 'spree_bestprice/products', formats: [:xml]))
          send_data(gz_xml, filename: 'products.xml.gz', type: 'application/x-gzip', disposition: 'inline')
        end
      end
    end

    private

    def ensure_feed_enabled
      unless store_integration('bestprice').present?
        render plain: 'BestPrice extension is not enabled for this store.', status: :not_found
      end
    end
  end
end
