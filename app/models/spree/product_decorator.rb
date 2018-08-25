Spree::Product.class_eval do
  include SolidusSeo::Model

  def seo_name
    "#{name} #{master.options_text}".strip
  end

  def seo_url
    spree_route_helper.product_url(self, host: store_host)
  end

  def seo_images
    return [] unless display_image.attachment.file?

    [
      url_helper.image_url(display_image.attachment.url(:large), host: store_host),
      url_helper.image_url(display_image.attachment.url(:xl), host: store_host),
      url_helper.image_url(display_image.attachment.url(:wide), host: store_host),
    ]
  end

  def seo_description
    plain_text(try(:meta_description).presence || try(:description))
  end

  def seo_brand
    @brand ||= taxons.detect { |it| it.root.name.downcase == 'brands' }.try(:name)
  end

  def seo_currency
    master.default_price.currency
  end

  def seo_price
    master.default_price.amount
  end

  def can_supply_any?
    variants_including_master.any?(&:can_supply?)
  end

  def seo_data
    {
      description: seo_description,
      name: seo_name,
      image_src: seo_images.first,
      og: {
        type: 'product',
        url: seo_url,
        brand: seo_brand,
        image: {
          _: :image_src,
          alt: seo_name,
        }
      },
      product: {
        price: {
          amount: seo_price,
          currency: seo_currency,
        }
      },
      twitter: {
        card: 'summary_large_image',
      }
    }
  end

  def jsonld_data
    {
      "@context": "http://schema.org/",
      "@type": "Product",
      "name": seo_name,
      "url": seo_url,
      "image": seo_images,
      "description": seo_name,
      "sku": sku,
      "brand": seo_brand,
      # TODO: ratings/reviews
      # "aggregateRating": {
      #   "@type": "AggregateRating",
      #   "ratingValue": "4.4",
      #   "reviewCount": "89"
      # },
      "offers": {
        "@type": "Offer",
        "priceCurrency": seo_currency,
        "price": seo_price,
        "itemCondition": "http://schema.org/NewCondition",
        "availability": "http://schema.org/#{ can_supply_any? ? 'InStock' : 'OutOfStock'}",
      }
    }
  end
end