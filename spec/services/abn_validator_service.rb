require 'rails_helper'

RSpec.describe AbnValidatorService, type: :service do
  subject(:abn_service) { described_class.call(abn_code) }

  describe '#call' do
    context 'when the abn code is valid' do
      let(:abn_code) { '10120000004' }

      it 'returns a valid response' do
        expect(abn_service[:valid]).to be(true)
        expect(abn_service[:tin_type]).to eq('au_abn')
        expect(abn_service[:formatted_abn]).to eq('10120000004')
      end
    end
    
    context 'when abn code is invalid' do
      let(:abn_code) { '10120000005' }
      
      it 'returns a invalid response' do
        expect(abn_service[:valid]).to be(false)
        expect(abn_service[:errors]).to eq(['Abn Algorithmic validation failed'])
      end
    end
  end
end
