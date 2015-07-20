require 'spec_helper'

describe Audumbla::Enrichments::CoarseGeocode do
  it_behaves_like 'a field enrichment'

  before do
    allow(Twofishes::Client)
      .to receive(:handle_response)
           .and_return(Twofishes::Result.from_response(georgia_response))
  end

  let(:georgia_response) { YAML::load_file('spec/fixtures/georgia.yml') }

  describe '#enrich_value' do
    let(:place) do
      build(:place,
            providedLabel: 'georgia',
            label: nil,
            exactMatch: nil,            
            countryCode: nil,
            parentFeature: nil,
            lat: nil,
            long: nil,
            alt: nil)
    end

    let(:prefLabel) { 'Georgia, United States' }
    let(:geoname_uri) { RDF::URI('http://sws.geonames.org/4197000/') }
    let(:country_code) { 'US' }
    let(:lat) { 32.75042 }
    let(:lng) { -83.50018 }
    let(:lcname_uri) do
      RDF::URI('http://id.loc.gov/authorities/names/n79023113')
    end

    describe '#enrich_value' do
      it 'returns the same place entity' do
        expect(subject.enrich_value(place)).to eq place
      end

      it 'retains providedLabel' do
        expect(subject.enrich_value(place))
          .to have_attributes(providedLabel: contain_exactly('georgia'))
      end

      it 'it gives the geoname as skos:exactMatch' do
        expect(subject.enrich_value(place).exactMatch.map(&:rdf_subject))
          .to contain_exactly(geoname_uri)
      end

      it 'adds LC closeMatches, if appropriate' do
        expect(subject.enrich_value(place).closeMatch.map(&:rdf_subject))
          .to contain_exactly(lcname_uri)
      end

      it 'enriches place with new data' do
        expect(subject.enrich_value(place))
          .to have_attributes(
                label: contain_exactly(prefLabel),
                countryCode: contain_exactly(country_code),
                lat: contain_exactly(be_within(0.01).of(lat)),
                long: contain_exactly(be_within(0.01).of(lng))
              )
      end

      context 'with lat/lng' do
        context 'and label' do
          let(:place) do
            build(:place,
                  providedLabel: 'georgia',
                  label: nil,
                  exactMatch: nil,            
                  countryCode: nil,
                  parentFeature: nil,
                  lat: lat,
                  long: lng,
                  alt: nil)
          end

          it 'gives result matching lat/lng' do
            expect(subject.enrich_value(place).exactMatch.map(&:rdf_subject))
              .to contain_exactly(geoname_uri)
          end

          it 'skips result not matching lat/lng' do
            place.lat = 41.9997
            place.long = 43.4998

            georgia_country_uri = RDF::URI('http://sws.geonames.org/614540/')

            # points are in bounding box for Georgia but not equal to center
            expect(subject.enrich_value(place).exactMatch.map(&:rdf_subject))
              .to contain_exactly(georgia_country_uri)
          end

          it 'selects no match if none match lat/lng' do
            place.lat = 41.9997
            place.long = -43.4998
            expect(subject.enrich_value(place).exactMatch).to be_empty
          end
        end
      end
    end
  end
end
