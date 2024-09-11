class AbnValidatorService < ApplicationService
  ABN_WEIGHTS = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19].freeze

  def initialize(abn_code)
    @abn_code = abn_code.strip
  end

  def call
    valid? ? success_response : failure_response([I18n.t('tin_validations.errors.abn_algorithmic_validation_failed')])
  end

  private

  def valid?
    digits = @abn_code.chars.map(&:to_i)
    subtract_checksum_digit(digits)
    calculate_weighted_sum(digits) % 89 == 0
  end

  def subtract_checksum_digit(digits)
    digits[0] -= 1
  end

  def calculate_weighted_sum(digits)
    digits.each_with_index.reduce(0) do |sum, (digit, index)|
      sum + digit * ABN_WEIGHTS[index]
    end
  end

  def success_response
    { valid: true, tin_type: 'au_abn', formatted_abn: @abn_code }
  end

  def failure_response(errors)
    { valid: false, errors: errors }
  end
end