xml.instruct! :xml, version: "1.0", encoding: "UTF-8"

bestprice_integration = store_integration('bestprice')
default_in_stock_availability = if bestprice_integration&.preferred_physical_pickup
  Spree::Integrations::Bestprice::IN_STOCK_AVAILABILITY[:pickup]
else
  Spree::Integrations::Bestprice::IN_STOCK_AVAILABILITY[:delivery]
end
default_out_of_stock_availability = bestprice_integration&.preferred_default_availability.presence ||
  Spree::Integrations::Bestprice::OUT_OF_STOCK_AVAILABILITY_OPTIONS.last

resolve_availability = lambda do |item_in_stock, override|
  override.presence || (item_in_stock ? default_in_stock_availability : default_out_of_stock_availability)
end

option_values_by_type_name = lambda do |variants, type_name|
  variants.flat_map(&:option_values)
    .select { |ov| ov.option_type.name.downcase == type_name }
    .map(&:presentation)
    .uniq
end

xml.store do
  cache [storefront_products_scope, current_currency] do
    xml.date Time.current.strftime("%Y-%m-%d %H:%M")

    xml.products do
      storefront_products_scope.find_each do |product|
        color_option_type = product.option_types.find { |ot| ot.name.downcase == 'color' }

        entries = if color_option_type
          product.variants
            .group_by { |v| v.option_values.find { |ov| ov.option_type_id == color_option_type.id } }
            .reject { |color_value, _| color_value.nil? }
            .map do |color_value, variants|
              title = if product.name.downcase.include?(color_value.presentation.downcase)
                product.name
              else
                "#{product.name} - #{color_value.presentation}"
              end

              {
                id: "#{product.id}-#{color_value.id}",
                title: title,
                variants: variants
              }
            end
        else
          [{ id: product.id.to_s, title: product.name, variants: product.variants.presence || [product.master] }]
        end

        breadcrumb_taxons = product_breadcrumb_taxons(product)

        entries.each do |entry|
          variants = entry[:variants]
          in_stock = variants.any?(&:in_stock?)
          availability = resolve_availability.call(in_stock, product.bestprice_availability)

          representative_variant = variants.find(&:in_stock?) || variants.first

          xml.product do
            xml.tag! "productId", entry[:id]

            xml.tag! "title" do
              xml.cdata! entry[:title]
            end

            xml.tag! "productURL" do
              xml.cdata! spree_storefront_resource_url(product)
            end

            entry_images = variants.flat_map(&:images).uniq
            entry_images = [product.default_image].compact if entry_images.empty?

            xml.tag! "image" do
              xml.cdata! spree_image_url(entry_images.first, width: 500, height: 500) if entry_images.first
            end

            entry_images[1..].each do |image|
              xml.tag! "additional_image" do
                xml.cdata! spree_image_url(image, width: 500, height: 500)
              end
            end

            xml.tag! "category_id", breadcrumb_taxons.last.id if breadcrumb_taxons.any?

            xml.tag! "category_name" do
              xml.cdata! breadcrumb_taxons.map(&:name).join('->')
            end

            xml.tag! "price", format('%.2f', representative_variant.display_price.to_d)

            xml.tag! "availability", availability

            xml.tag! "stock", in_stock ? 'Y' : 'N'

            xml.tag! "manufacturer" do
              xml.cdata! product.brand_taxon&.name.to_s
            end

            xml.tag! "ean", representative_variant.barcode.presence || product.barcode

            size = option_values_by_type_name.call(variants, 'size')
            xml.tag! "size", size.join(',') if size.any?

            xml.tag! "weight", "#{product.weight} #{product.weight_unit}" if product.weight.present?

            color = option_values_by_type_name.call(variants, 'color')
            xml.tag! "color", color.join(',') if color.any?

            if product.storefront_description.present?
              xml.tag! "description" do
                xml.cdata! product.storefront_description&.truncate(10000)
              end
            end

            xml.tag! "quantity", variants.sum(&:total_on_hand)
          end
        end
      end
    end
  end
end
