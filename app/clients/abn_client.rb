require 'net/http'
require 'uri'
require 'nokogiri'

class AbnApiClient
  BASE_URL = 'http://localhost:8080/queryABN'
  SUCCESS_CODE = 200
  NOT_FOUND_CODE = 404
  SERVER_ERROR_CODE = 500

  def initialize(abn)
    @abn = abn
  end

  def fetch_business_info
    uri = build_uri
    response = get_response(uri)

    handle_response(response)
  rescue StandardError => e
    error_response("Error occurred: #{e.message}")
  end

  private

  def build_uri
    URI.parse("#{BASE_URL}?abn=#{@abn}")
  end

  def get_response(uri)
    Net::HTTP.get_response(uri)
  end

  def handle_response(response)
    case response.code.to_i
    when SUCCESS_CODE
      parse_response(response.body)
    when NOT_FOUND_CODE
      error_response('Business is not registered')
    when SERVER_ERROR_CODE
      error_response('Registration API could not be reached')
    else
      error_response('Unexpected error occurred')
    end
  end

  def parse_response(body)
    xml = Nokogiri::XML(body)
    gst_registered = extract_gst_status(xml)
    business_name = extract_business_name(xml)
    address = extract_address(xml)

    if gst_registered
      success_response(business_name, address)
    else
      error_response('Business is not registered for GST')
    end
  end

  def extract_gst_status(xml)
    xml.at_xpath('//goodsAndServicesTax').text == 'true'
  end

  def extract_business_name(xml)
    xml.at_xpath('//organisationName').text
  end

  def extract_address(xml)
    state_code = xml.at_xpath('//address/stateCode').text
    postcode = xml.at_xpath('//address/postcode').text
    "#{state_code} #{postcode}"
  end

  def success_response(name, address)
    {
      valid: true,
      business_registration: {
        name: name,
        address: address
      }
    }
  end

  def error_response(message)
    {
      valid: false,
      errors: [message]
    }
  end
end
