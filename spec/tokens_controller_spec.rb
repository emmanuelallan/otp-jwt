require 'spec_helper'

RSpec.describe TokensController, type: :request do
  let(:user) { create_user }
  let(:params) { }

  around do |examp|
    perform_enqueued_jobs(&examp)
  end

  before do
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
    post(tokens_path, params: params.to_json, headers: json_headers)
  end

  it { expect(response).to have_http_status(:forbidden) }

  context 'with good email and no otp' do
    let(:params) { { email: user.email } }

    it do
      expect(response).to have_http_status(:bad_request)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq(OTP::Mailer.default[:subject])
    end
  end

  context 'with good email and bad otp' do
    let(:params) { { email: user.email, otp: FFaker::Internet.password } }

    it do
      expect(response).to have_http_status(:forbidden)
      expect(ActionMailer::Base.deliveries.size).to eq(0)
    end
  end

  context 'with good email and good otp' do
    let(:params) { { email: user.email, otp: user.otp } }

    it do
      expect(response).to have_http_status(:created)
      expect(User.from_jwt(response_json['token'])).to eq(user)
      expect(ActionMailer::Base.deliveries.size).to eq(0)

      expect(user.reload.last_login_at).not_to be_blank
    end
  end

  context 'with magic link' do
    let(:magic_link) { OTP::JWT::MagicLink.create!(user: user, token: SecureRandom.hex(32), expires_at: 15.minutes.from_now) }
    it 'authenticates with a valid magic link' do
      get magic_link_path(token: magic_link.token)
      expect(response).to have_http_status(:ok)
      expect(response_json['token']).not_to be_nil
    end
    it 'rejects an invalid magic link' do
      get magic_link_path(token: 'invalid')
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'rate limiting' do
    before { Rails.cache.clear }
    let(:email) { user.email }
    let(:ip) { '1.2.3.4' }
    let(:headers) { json_headers.merge('REMOTE_ADDR' => ip) }

    it 'limits OTP requests per user/email' do
      5.times do
        post '/request_otp', params: { email: email }.to_json, headers: headers
      end
      post '/request_otp', params: { email: email }.to_json, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response_json['error']['code']).to eq('RATE_LIMITED')
    end

    it 'limits magic link requests per IP' do
      magic_link = OTP::JWT::MagicLink.create!(user: user, token: SecureRandom.hex(32), expires_at: 15.minutes.from_now)
      5.times do
        get '/magic_link', params: { token: magic_link.token }, headers: headers
      end
      get '/magic_link', params: { token: magic_link.token }, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response_json['error']['code']).to eq('RATE_LIMITED')
    end
  end

  describe 'error code responses' do
    it 'returns error code for invalid OTP' do
      post '/verify_otp', params: { email: user.email, otp: 'bad' }.to_json, headers: json_headers
      expect(response_json['error']['code']).to eq('OTP_INVALID')
    end
    it 'returns error code for invalid magic link' do
      get '/magic_link', params: { token: 'invalid' }, headers: json_headers
      expect(response_json['error']['code']).to eq('INVALID_MAGIC_LINK')
    end
  end

  describe 'refresh' do
    let(:refresh_token) { OTP::JWT::RefreshToken.create!(user: user, token: SecureRandom.hex(32), expires_at: 1.day.from_now) }
    it 'returns new tokens for valid refresh token' do
      post '/refresh', params: { refresh_token: refresh_token.token }.to_json, headers: json_headers
      expect(response).to have_http_status(:ok)
      expect(response_json['token']).not_to be_nil
      expect(response_json['refresh_token']).not_to be_nil
    end
    it 'returns error for invalid refresh token' do
      post '/refresh', params: { refresh_token: 'bad' }.to_json, headers: json_headers
      expect(response).to have_http_status(:unauthorized)
      expect(response_json['error']).not_to be_nil
    end
  end

  describe 'sign_out' do
    it 'blacklists the current token and returns no content' do
      allow_any_instance_of(User).to receive(:blacklist_token).and_return(true)
      delete '/sign_out', headers: jwt_auth_header(user)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'request_otp error handling' do
    it 'returns error code if mailer fails' do
      allow_any_instance_of(User).to receive(:email_otp).and_raise(StandardError, 'fail')
      post '/request_otp', params: { email: user.email }.to_json, headers: json_headers
      expect(response_json['error']['code']).to eq('OTP_SEND_FAILED')
    end
  end

  describe 'magic_link error handling' do
    it 'returns error code if magic link is revoked' do
      magic_link = OTP::JWT::MagicLink.create!(user: user, token: SecureRandom.hex(32), expires_at: 15.minutes.from_now, revoked_at: Time.current)
      get '/magic_link', params: { token: magic_link.token }, headers: json_headers
      expect(response_json['error']['code']).to eq('INVALID_MAGIC_LINK')
    end
    it 'returns error code if magic link is expired' do
      magic_link = OTP::JWT::MagicLink.create!(user: user, token: SecureRandom.hex(32), expires_at: 1.minute.ago)
      get '/magic_link', params: { token: magic_link.token }, headers: json_headers
      expect(response_json['error']['code']).to eq('INVALID_MAGIC_LINK')
    end
  end
end
