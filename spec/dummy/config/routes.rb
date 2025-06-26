Rails.application.routes.draw do
  mount OTP::JWT::Engine => '/auth'
  root to: 'home#index'
end
