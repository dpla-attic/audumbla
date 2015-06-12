require 'twofishes'
require 'geokit'

module Audumbla::Enrichments
  ##
  # Enriches a `DPLA::MAP::Place` node by running its data through external 
  # geocoders, using heuristics to determine a matching feature from GeoNames,
  # and repopulating the `Place` with related data.
  #
  # If the existing `Place` contains data other than a `providedLabel`, that 
  # data will be used as context for evaluating interpretations. For example: 
  # a `Place` with an existing latitude and longitude will verify that the
  # point is within the bounding box for a candidate match.
  # 
  # `skos:exactMatch` are reserved for the GeoNames features returned by the 
  # geocoder. Other matching URIs (currently: LC authorities) are included as
  # `skos:closeMatch`
  #
  # @example enriching from a `#providedLabel`
  #   
  #    place = DPLA::MAP::Place.new.tap { |p| p.providedLabel = 'Georgia' }
  #    CoarseGeocode.new.enrich_value.dump :ttl
  #    # [
  #    #    a <http://www.europeana.eu/schemas/edm/Place>;
  #    #    <http://dp.la/about/map/providedLabel> "Georgia";
  #    #    <http://www.geonames.org/ontology#countryCode> "US";
  #    #    <http://www.w3.org/2003/01/geo/wgs84_pos#lat> 3.275042e1;
  #    #    <http://www.w3.org/2003/01/geo/wgs84_pos#long> -8.350018e1;
  #    #    <http://www.w3.org/2004/02/skos/core#closeMatch> <http://id.loc.gov/authorities/names/n79023113>;
  #    #    <http://www.w3.org/2004/02/skos/core#exactMatch> <http://sws.geonames.org/4197000/>;
  #    #    <http://www.w3.org/2004/02/skos/core#prefLabel> "Georgia, United States"
  #    # ] .
  #
  # @example enriching from a `#providedLabel` with lat/lng guidance
  #   
  #    place = DPLA::MAP::Place.new.tap do |p| 
  #      p.providedLabel = 'Georgia'
  #      p.lat = 41.9997
  #      p.long = 43.4998
  #    end
  #    
  #    CoarseGeocode.new.enrich_value.dump :ttl
  #    # [
  #    #    a <http://www.europeana.eu/schemas/edm/Place>;
  #    #    <http://dp.la/about/map/providedLabel> "Georgia";
  #    #    <http://www.geonames.org/ontology#countryCode> "GE";
  #    #    <http://www.w3.org/2003/01/geo/wgs84_pos#lat> 4.199998e1;
  #    #    <http://www.w3.org/2003/01/geo/wgs84_pos#long> 4.34999e1;
  #    #    <http://www.w3.org/2004/02/skos/core#exactMatch> <http://sws.geonames.org/614540/>;
  #    #    <http://www.w3.org/2004/02/skos/core#prefLabel> "Georgia"
  #    # ] .
  #
  class CoarseGeocode
    include Audumbla::FieldEnrichment

    DEFAULT_DISTANCE_THRESHOLD_KMS = 100

    Twofishes.configure do |config|
      config.host = 'localhost' 
      config.port = 8080
      config.timeout = 100
      config.retries = 2 
    end

    ##
    # Enriches the given value against the TwoFishes coarse geocoder. This 
    # process adds a `skos:exactMatch` for a matching GeoNames URI, if any, and
    # populates the remaining place data to the degree possible from the matched
    # feature.
    # 
    # @param [DPLA::MAP::Place] value  the place to geocode
    #
    # @return [DPLA::MAP::Place] the inital place, enriched via coarse geocoding
    def enrich_value(value)
      return value unless value.is_a? DPLA::MAP::Place
      interpretations = geocode(value.providedLabel.first, 
                                [],
                                maxInterpretations: 5)
      match = interpretations.find { |interp| match?(interp, value) }
      match.nil? ? value : enrich_place(value, match.feature)
    end

    ##
    # Checks that we are satisfied with the geocoder's best matches prior to 
    # acceptance. Most tweaks to the geocoding process should be taken care
    # of at the geocoder itself, but a simple accept/reject of the points 
    # offered is possible here. This allows existing data about the place
    # to be used as context.
    #
    # For example, this method returns false if `place` contains latitude
    # and longitude, but the candidate match has a geometry far away from those
    # given.
    #
    # @param [GeocodeInterpretation] interpretation  a twofishes interpretation
    # @param [#lat#long] place  a place to verify a match against
    #
    # @result [Boolean] true if the interpretation is accepted
    def match?(interpretation, place)
      return true if place.lat.empty? || place.long.empty?

      point = Geokit::LatLng.new(place.lat.first, place.long.first)
      if interpretation.geometry.bounds.nil?
        # measure distance between point centers
        distance = twofishes_point_to_geokit(interpretation.geometry.center)
                   .distance_to(point, unit: :kms)
        return distance < DEFAULT_DISTANCE_THRESHOLD_KMS
      end
        
      twofishes_bounds_to_geokit(interpretation.geometry.bounds)
        .contains?(point)
    end

    private

    ##
    # Populates a DPLA::MAP::Place with data from a given feature. This 
    # overwrites existing data with the exception of the identity (URI or node 
    # id) and the `providedLabel`. `exactMatch`, `closeMatch`, `label` 
    # (skos:prefLabel)and all other geographic data is replaced.
    # 
    # @param [DPLA::MAP::Place] place  a place to enrich
    # @param [GeocodeFeature] feature  a twofishes feature whose data should be
    #   added to place.
    #
    # @return [DPLA::MAP::Place] the original place enriched
    def enrich_place(place, feature)
      place.label = feature.display_name
      place.exactMatch = feature_to_geoname_uris(feature)
      place.closeMatch = feature_to_close_matches(feature, 
                                                  /^http\:\/\/id\.loc\.gov\/.*/)
      place.countryCode = feature.cc
      place.lat = feature.geometry.center.lat
      place.long = feature.geometry.center.lng

      place
    end

    ##
    # Extracts geonameids for the given feature and converts them into URIs
    #
    # @param [GeocodeFeature] feature the feature to identify
    #
    # @return [Array<RDF::URI>] a list of geoname URIs. Generally, this will only 
    #   contain one exactly matching geonameid in URI form.
    def feature_to_geoname_uris(feature)
      geoname_ids = feature.ids.select { |id| id.source == :geonameid.to_s }
      geoname_ids.map { |id| RDF::URI('http://sws.geonames.org') / id.id + '/' }
    end

    ##
    # Extracts URIs for closely matching terms in other authority or knowledege
    # organization systems
    #
    # @param [GeocodeFeature] feature the feature to identify
    # @param [Regexp] patterns a splat argument containing any number of 
    #   patterns matching
    #
    # @return [Array<RDF::URI>] a list of matching ids
    def feature_to_close_matches(feature, *patterns)
      union = Regexp.union(patterns)
      feature.attributes.urls.select { |str| union.match(str) }
        .map { |id| RDF::URI(id) }
    end
    
    ##
    # Sends a geocode request. This is used in lieu of `Twofishes#geocode`, 
    # since that method does not allow passing parameters other than 
    # `responseIncludes`.
    #
    # @param [#to_s] location  the string to try to match
    # @param [Array] includes  a list of twofishes include constants
    # @param [Hash<Symbol, #to_s> params  property and value pairs for 
    #   parameters to pass to the request
    #
    # @see Twofishes#geocode
    # @see Twofishes::Client
    def geocode(location, includes = [], params = {})
      client = Twofishes::Client
      client.send(:handle_response) do
        request = GeocodeRequest.new(query: location, responseIncludes: includes)
        params.each { |prop, val| request.send("#{prop}=".to_sym, val) }
        client.thrift_client.geocode(request)
      end
    end

    ##
    # @param [#lat#long] point  a twofishes point to convert to Geokit
    #
    # @return [Geokit::LatLng]
    def twofishes_point_to_geokit(point)
      Geokit::LatLng.new(point.lat, point.lng)
    end

    ##
    # @param [#ne#sw] bounds  a twofishes binding box to convert to Geokit
    #
    # @return [Geokit::Bounds]
    def twofishes_bounds_to_geokit(bounds)
      Geokit::Bounds.new(twofishes_point_to_geokit(bounds.sw), 
                         twofishes_point_to_geokit(bounds.ne))
    end
  end
end
