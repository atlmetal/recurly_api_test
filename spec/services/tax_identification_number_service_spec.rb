require 'rails_helper'

RSpec.describe TaxIdentificationNumberService, type: :service do
  subject(:tin_service) { described_class.call(params) }

  describe '#call' do
    context 'with valid TIN' do
      context 'for CA (Canada) GST' do
        let(:params) { { country_code: 'CA', identification_number: '123456789' } }

        it 'returns a valid response with the correct format' do
          expect(tin_service[:valid]).to be(true)
          expect(tin_service[:tin_type]).to eq('ca_gst')
          expect(tin_service[:formatted_tin]).to eq('123456789RT00001')
        end
      end
    end

    context 'with invalid TIN' do
      context 'unsupported country' do
        let(:params) { { country_code: 'XX', identification_number: '123456789' } }

        it 'returns an error for unsupported country' do
          expect(tin_service[:valid]).to be(false)
          expect(tin_service[:errors]).to eq(I18n.t('tin_validations.errors.unsupported_country'))
        end
      end

      context 'invalid format for valid country' do
        let(:params) { { country_code: 'CA', identification_number: 'invalidTIN' } }

        it 'returns an error for invalid TIN format' do
          expect(tin_service[:valid]).to be(false)
          expect(tin_service[:errors]).to eq(I18n.t('tin_validations.errors.invalid_tin_format'))
        end
      end
    end
  end
end
