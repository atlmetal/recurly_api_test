require 'rails_helper'

RSpec.describe TaxesController, type: :controller do
  let(:valid_params) { { validation_params: { country_code: 'AU', identification_number: '10120000004' } } }
  let(:invalid_params) { { validation_params: { country_code: 'XX', identification_number: '123' } } }

  describe '#transform' do
    context 'when the request has valid params' do
      let(:service_response) { { valid: true, tin_type: 'au_abn', formatted_tin: '10120000 004' } }

      before { allow(TaxIdentificationNumberService).to receive(:call).and_return(service_response) }

      it 'calls the TaxIdentificationNumberService and returns a successful response' do
        get :transform, params: valid_params

        expect(TaxIdentificationNumberService).to have_received(:call).with(
          ActionController::Parameters.new(valid_params[:validation_params]).
          permit(:country_code, :identification_number)
        )
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq(service_response.as_json)
      end
    end

    context 'when the request has invalid params' do
      let(:service_response) { { valid: false, errors: ['Invalid country code'] } }

      before { allow(TaxIdentificationNumberService).to receive(:call).and_return(service_response) }

      it 'returns a validation error from the service' do
        allow(TaxIdentificationNumberService).to receive(:call).and_return(service_response)

        get :transform, params: invalid_params

        expect(TaxIdentificationNumberService).to have_received(:call).with(
          ActionController::Parameters.new(invalid_params[:validation_params]).
          permit(:country_code, :identification_number)
        )

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq(service_response.as_json)
      end
    end

    context 'when the request is missing params' do
      it 'raises a parameter missing error' do
        expect {
          get :transform, params: {}
        }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end
end

