module Spree
  module ProductDecorator
    def bestprice_availability
      private_metadata['bestprice_availability'].presence
    end

    def bestprice_availability=(value)
      self.private_metadata = private_metadata.merge('bestprice_availability' => value.presence)
    end

    Spree::Product.prepend self
  end
end
