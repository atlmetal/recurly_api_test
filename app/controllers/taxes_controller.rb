class TaxesController < ApplicationController
  def transform
    render json: tin_service
  end

  private

  def tin_service
    @tin_service ||= TaxIdentificationNumberService.call(permit_tin_params)
  end

  def permit_tin_params
    params.require(:validation_params).permit(:country_code, :identification_number)
  end
end
