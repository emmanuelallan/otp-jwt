Otp::Jwt::Engine.routes.draw do
  post "/request_otp", to: "tokens#request_otp"
  post "/verify_otp", to: "tokens#verify_otp"
  post "/refresh", to: "tokens#refresh"
  delete "/sign_out", to: "tokens#sign_out"
  get "/magic_link", to: "tokens#magic_link"
end
