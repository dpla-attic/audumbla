module Audumbla
  autoload :Enrichment, 'audumbla/enrichment'
  autoload :FieldEnrichment, 'audumbla/field_enrichment'

  module Enrichments
    autoload :CoarseGeocode, 'audumbla/enrichments/coarse_geocode'
  end
end
