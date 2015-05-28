require 'spec_helper'

describe Audumbla::Enrichment do
  subject { klass.new }

  let(:klass) { Class.new { include Audumbla::Enrichment } }

  it_behaves_like 'a generic enrichment'

  describe '#enrich_value' do
    it 'is abstract' do
      expect { subject.enrich_value(nil) }.to raise_error NotImplementedError
    end
  end
end
