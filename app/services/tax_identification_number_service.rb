class TaxIdentificationNumberService < ApplicationService
  TIN_FORMATS = {
    'AU' => {
      'au_abn' => { regex: /\A\d{11}\z/, format: 'NN NNN NNN NNN', length: 11 },
      'au_acn' => { regex: /\A\d{9}\z/, format: 'NNN NNN NNN', length: 9 }
    },
    'CA' => {
      'ca_gst' => { regex: /\A\d{9}RT\d{5}\z/, format: 'NNNNNNNNNRT00001', length: 9 }
    },
    'IN' => {
      'in_gst' => { regex: /\A\d{2}[A-Z]{5}\d{4}[A-Z]{1}\d{1}Z\d{1}\z/, format: 'NNXXXXXXXXXXNAN', length: 15 }
    }
  }.freeze

  ERRORS = {
    unsupported_country: I18n.t('tin_validations.errors.unsupported_country'),
    invalid_format: I18n.t('tin_validations.errors.invalid_tin_format')
  }.freeze

  def initialize(params)
    @country_code = params[:country_code]
    @tin = params[:identification_number].gsub(/\s+/, "")
  end

  def call
    return unsupported_country_response unless supported_country?

    type, format_details = find_format_details
    return validate_abn if type == 'au_abn'
    
    type ? valid_tin_response(type, format_details) : invalid_format_response
  end

  private

  def supported_country?
    TIN_FORMATS.key?(@country_code)
  end

  def unsupported_country_response
    { valid: false, errors: ERRORS[:unsupported_country] }
  end

  def find_format_details
    TIN_FORMATS[@country_code].find do |type, details|
      add_code if ca_gst_needs_code?(type)
      tin_matches_format?(details[:regex])
    end
  end

  def ca_gst_needs_code?(type)
    type == 'ca_gst' && @tin.size == 9
  end

  def tin_matches_format?(regex)
    @tin.match?(regex)
  end

  def validate_abn
    @validate_abn ||= AbnValidatorService.call(@tin)
  end

  def valid_tin_response(type, format_details)
    formatted_tin = format_tin(format_details[:format])
    { valid: true, tin_type: type, formatted_tin: formatted_tin }
  end

  def invalid_format_response
    { valid: false, errors: ERRORS[:invalid_format] }
  end

  def add_code
    @tin += 'RT00001'
  end

  def format_tin(format)
    index = 0
    format.gsub(/[NXA]/) { @tin[index].tap { index += 1 } }
  end
end
