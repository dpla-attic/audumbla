require 'spec_helper'

describe Krikri::Enrichment do
  subject { klass.new }

  let(:klass) { Class.new { include Krikri::Enrichment } }

  it_behaves_like 'a generic enrichment'

  describe '#enrich_value' do
    it 'is abstract' do
      expect { subject.enrich_value(nil) }.to raise_error NotImplementedError
    end
  end
end
