module Audumbla
  autoload :Enrichment,      'audumbla/enrichment'
  autoload :FieldEnrichment, 'audumbla/field_enrichment'

  module Enrichments
    autoload :CoarseGeocode,               'audumbla/enrichments/coarse_geocode'
    autoload :ConvertToSentenceCase,       'audumbla/enrichments/convert_to_sentence_case'
    autoload :StripEndingPunctuation,      'audumbla/enrichments/strip_ending_punctuation'
    autoload :StripHtml,                   'audumbla/enrichments/strip_html'
    autoload :StripLeadingPunctuation,     'audumbla/enrichments/strip_leading_punctuation'
    autoload :StripLeadingColons,          'audumbla/enrichments/strip_leading_colons'
    autoload :StripPunctuation,            'audumbla/enrichments/strip_punctuation'
    autoload :StripWhitespace,             'audumbla/enrichments/strip_whitespace'
  end
end
