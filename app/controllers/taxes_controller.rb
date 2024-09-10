class TaxesController < ApplicationController
  def transform
    tin_service.call

    render json: tin_service.generate_response, status: :ok
  rescue StandardError => error
    render json: { valid: false, errors: [error.class], message: error.message }, status: :bad_request
  end

  private

  def tin_service
    @tin_service ||= TaxIdentificationNumberService.new(
      country_code: params['country_code'], identification_number: params['identification_number']
    )
  end
end
