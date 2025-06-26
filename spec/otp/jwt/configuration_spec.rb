require 'spec_helper'

RSpec.describe OTP::JWT::Configuration do
  let(:config) { OTP::JWT::Configuration.new }

  describe 'defaults' do
    it 'has default otp_length' do
      expect(config.otp_length).to eq(6)
    end

    it 'has default otp_expiration' do
      expect(config.otp_expiration).to eq(15.minutes)
    end

    it 'has default jwt_expiration' do
      expect(config.jwt_expiration).to eq(24.hours)
    end

    it 'has default refresh_token_expiration' do
      expect(config.refresh_token_expiration).to eq(7.days)
    end

    it 'has default max_failed_attempts' do
      expect(config.max_failed_attempts).to eq(5)
    end

    it 'has default lockout_duration' do
      expect(config.lockout_duration).to eq(1.hour)
    end
  end

  describe 'customization' do
    it 'allows customizing otp_length' do
      config.otp_length = 8
      expect(config.otp_length).to eq(8)
    end

    it 'allows customizing otp_expiration' do
      config.otp_expiration = 30.minutes
      expect(config.otp_expiration).to eq(30.minutes)
    end

    it 'allows customizing jwt_expiration' do
      config.jwt_expiration = 48.hours
      expect(config.jwt_expiration).to eq(48.hours)
    end

    it 'allows customizing refresh_token_expiration' do
      config.refresh_token_expiration = 14.days
      expect(config.refresh_token_expiration).to eq(14.days)
    end

    it 'allows customizing max_failed_attempts' do
      config.max_failed_attempts = 10
      expect(config.max_failed_attempts).to eq(10)
    end

    it 'allows customizing lockout_duration' do
      config.lockout_duration = 2.hours
      expect(config.lockout_duration).to eq(2.hours)
    end
  end

  describe 'error handling' do
    it 'allows customizing error handler' do
      custom_handler = ->(controller) { controller.render json: { error: 'Custom error' }, status: :bad_request }
      config.on_forbidden_request = custom_handler
      expect(config.on_forbidden_request).to eq(custom_handler)
    end
  end
end
