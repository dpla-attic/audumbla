require 'spec_helper'

describe Krikri::FieldEnrichment do
  subject { enrichment_class.new }

  let(:enrichment_class) { Class.new { include Krikri::FieldEnrichment } }

  context 'with implementation' do
    before { allow(subject).to receive(:enrich_value).and_return('moomin') }

    it_behaves_like 'a field enrichment'
  end

  describe '#enrich_value' do
    it 'is abstract' do
      expect { subject.enrich_value(nil) }.to raise_error NotImplementedError
    end
  end
end
