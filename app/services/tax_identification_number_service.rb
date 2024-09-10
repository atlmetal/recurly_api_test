require "active_support/hash_with_indifferent_access"

class TaxIdentificationNumberService < ApplicationService
  def initialize(country_code:, identification_number:)
    @country_code = country_code
    @identification_number = identification_number

    country_code_information
  end

  COUNTRY_CODES = ActiveSupport::HashWithIndifferentAccess.new({
    AU: [
      {
        country: 'Australia',
        tin_type: 'au_abn',
        tin_name: 'Australian Business Number',
        length_validation: -> (str) { str.tr(' ', '').size == 11 },
        regex: -> (str) { str.match?(/^\d{2} \d{3} \d{3} \d{3}$/) },
        format: -> (str) { "#{str[0..1]} #{str[2..4]} #{str[5..7]} #{str[8..10]}" }
      },
      {
        country: 'Australia',
        tin_type: 'au_acn',
        tin_name: 'Australian Company Number',
        length_validation: -> (str) { str.tr(' ', '').size == 9 },
        regex: -> (str) { str.match?(/^\d{3} \d{3} \d{3}$/) },
        format: -> (str) { "#{str[0..2]} #{str[3..5]} #{str[6..8]}" }
      }
    ],
    CA: [
      {
        country: 'Canada',
        tin_type: 'ca_gst',
        tin_name: 'Canada GST Number',
        length_validation: -> (str) { str.gsub(/RT\d{5}$/, '').size == 9 },
        regex: -> (str) { str.match?(/^\d{9}RT\d{5}$/) },
        format: -> (str) { "#{str}RT00001" }
      }
    ],
    IN: [
      {
        country: 'India',
        tin_type: 'in_gst',
        tin_name: 'Indian GST Number',
        length_validation: -> (str) { str.size == 15 },
        regex: -> (str) { str.match?(/^\d{2}[A-Za-z0-9]{10}\d[A-Za-z]\d$/) },
        format: -> (str) { str }
      }
    ]
  })

  class CountryCodeNotFoundException < StandardError; end
  class InvalidParametersException < StandardError; end

  def call
    raise InvalidParametersException.new("Missing parameters") unless @identification_number && @country_code

    @formatted_identification = @identification_number if @country_code_information[:regex].call(@identification_number)

    return if @formatted_identification 

    @formatted_identification = @country_code_information[:format].call(@identification_number)
  end

  def generate_response
    { valid: true, tin_type: @country_code_information[:tin_type], formatted_tin: @formatted_identification, errors: [] }
  end

  private

  def country_code_information
    @country_code_information = COUNTRY_CODES[@country_code.upcase].find { |cd| cd[:length_validation].call(@identification_number) }

    raise CountryCodeNotFoundException.new("Country code not found: #{@country_code}") unless @country_code_information
  end
end
