# OTP JWT

A modern, secure passwordless authentication solution for Rails APIs using One-Time Passwords (OTP) and JSON Web Tokens (JWT). This gem provides a complete authentication flow that eliminates the need for traditional passwords while maintaining high security standards.

## Features

- ✨ **OTP Delivery**: Send one-time codes via email or SMS
- 🔐 **JWT Authentication**: Secure token-based authentication
- 🔗 **Magic Links**: Email-based single-use login links
- 🔄 **Token Refresh**: Secure token renewal mechanism
- 🔒 **Account Locking**: Protection against brute-force attacks
- 🔗 **Customizable**: Fully pluggable delivery methods and token generation
- 🔧 **Easy Integration**: Simple Rails generator for quick setup
- ✅ **Production Ready**: Comprehensive testing and security measures

## Requirements

- Ruby 3.4.0 or higher
- Rails 8.0 or higher
- Database with Active Record support
- Email/SMS delivery service (configurable)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'otp-jwt'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install otp-jwt
```

## Setup

1. Run the generator:

```bash
rails generate otp_jwt:install
```

2. Run the migrations:

```bash
rails db:migrate
```

3. Add OTP-JWT to your User model:

```ruby
class User < ApplicationRecord
  include OTP::JWT::Authenticatable
  
  # Optional: Customize OTP delivery
  def deliver_otp(otp)
    # Your custom delivery logic here
  end
end
```

## Usage

### 1. Request OTP

```ruby
# Generate and send OTP
user.generate_and_send_otp

# Generate magic link
user.generate_magic_link
```

### 2. Verify OTP

```ruby
# Verify OTP code
user.verify_otp('123456')

# Verify magic link token
user.verify_magic_link_token('token')
```

### 3. Get JWT

```ruby
# Get JWT token
user.generate_jwt

# Refresh JWT
user.refresh_jwt
```

### 4. Sign Out

```ruby
# Sign out user
user.sign_out

# Blacklist token
user.blacklist_token('token')
```

## Configuration

```ruby
OTP::JWT.configure do |config|
  # OTP Settings
  config.otp_length = 6
  config.otp_expiration = 15.minutes
  
  # JWT Settings
  config.jwt_expiration = 24.hours
  config.refresh_token_expiration = 7.days
  
  # Account Locking
  config.max_failed_attempts = 5
  config.lockout_duration = 1.hour
  
  # Custom Error Handling
  config.on_forbidden_request = ->(controller) do
    controller.render json: { error: 'Invalid credentials' }, status: :forbidden
  end
end
```

## Security Features

- Account locking after multiple failed attempts
- Token blacklisting
- Rate limiting
- Secure token generation and verification
- Encrypted OTP storage
- Secure passwordless authentication flow

## Testing

```bash
bundle exec rspec
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE.txt file for details
</p>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'otp-jwt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install otp-jwt

## Quick Start

### 1. Install the gem

```bash
rails generate otp:jwt:install
```

This creates the initializer at `config/initializers/otp_jwt.rb`.

### 2. Add OTP/JWT to your User model

```bash
rails generate otp:jwt:user User
```

This will:
- Add the necessary OTP/JWT fields to your User model
- Include the required concerns in your User model
- Create a migration to add the required database fields

### 3. Run migrations

```bash
rails db:migrate
```

### 4. Configure your User model

Update your User model to implement OTP delivery:

```ruby
class User < ApplicationRecord
  include OTP::JWT::Concerns::User
  
  # Implement email OTP delivery
  def email_otp
    UserMailer.otp_email(self, otp).deliver_later
  end
  
  # Optional: Implement SMS OTP delivery
  def sms_otp
    SmsService.send_otp(phone_number, otp) if phone_number.present?
  end
end
```

### 5. Mount the engine in your routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount OTP::JWT::Engine => '/auth'
end
```

### 6. Configure your initializer

```ruby
# config/initializers/otp_jwt.rb
OTP::JWT.configure do |config|
  # Set your JWT secret key
  config.jwt_signature_key = ENV['OTP_JWT_SIGNATURE_KEY']
  
  # Configure OTP settings
  config.otp_digits = 6
  config.max_otp_attempts = 5
  config.unlock_in = 15.minutes
end
```

## API Endpoints

Once installed, the following endpoints are available:

- `POST /auth/request_otp` - Request OTP via email
- `POST /auth/verify_otp` - Verify OTP and get JWT
- `POST /auth/refresh` - Refresh access token
- `DELETE /auth/sign_out` - Sign out and blacklist token
- `GET /auth/magic_link` - Authenticate via magic link

## Usage

 * [OTP for Active Record models](#otp-for-active-record-models)
   * [Mailer support](#mailer-support)
   * [SMS delivery support](#sms-delivery-support)
 * [JWT for Active Record models](#jwt-for-active-record-models)
 * [JWT authorization](#jwt-authorization)
 * [JWT authentication](#jwt-authentication)
 * [JWT Tokens](#jwt-tokens)

---

To start using it with Rails, add this to an initializer and configure your
keys:

```ruby
# config/initializers/otp-jwt.rb
require 'otp'
# To load the JWT related support.
require 'otp/jwt'

# Set to 'none' to disable verification at all.
# OTP::JWT::Token.jwt_algorithm = 'HS256'

# How long the token will be valid.
# OTP::JWT::Token.jwt_lifetime = 60 * 60 * 24

OTP::JWT::Token.jwt_signature_key = ENV['YOUR-SIGN-KEY']
```
### OTP for Active Record models

To add support for OTP to your models, use the `OTP::ActiveRecord` concern:

```ruby
class User < ActiveRecord::Base
  include OTP::ActiveRecord

  ...
end
```

This will provide two new methods which you can use to generate and verify
one time passwords:
 * `User#otp`
 * `User#verify_otp`

This concern expects two attributes to be provided by the model, the:
 * `otp_secret`: of type string, used to store the OTP signature key
 * `otp_counter`: of type integer, used to store the OTP counter
 * `expire_jwt_at`: of type datetime, **optional** and used to force a token to expire

A migration to add these two looks like this:
```
$ rails g migration add_otp_to_users otp_secret:string otp_counter:integer
```

Generate `opt_secret` by running the following in rails console if you have preexisting user data:
```
User.all.each do |u|
  u.save()
end
```

##### Force a token to expire

If there's an `expire_jwt_at` value that is in the past, the user token will
be reset and it will require a new authentication to receive a working token.

This is handy if the user access needs to be scheduled and/or removed.
#### Mailer support

You can use the built-in mailer to deliver the OTP, just require it and
overwrite the helper method:

```ruby
require 'otp/mailer'

class User < ActiveRecord::Base
  include OTP::ActiveRecord

  def email_otp
    OTP::Mailer.otp(email, otp, self).deliver_later
  end
end
```

To customize the mailer subject, address and template, update the defaults:

```ruby
require 'otp/mailer'

OTP::Mailer.default subject: 'Your App magic password 🗝️'
OTP::Mailer.default from: ENV['DEFAUL_MAILER_FROM']
# Tell mailer to use the template from app/views/otp/mailer/otp.html.erb
OTP::Mailer.prepend_view_path(Rails.root.join('app', 'views'))
```

#### SMS delivery support

You can use the built-in job to deliver the OTP via SMS, just require it and
overwrite the helper method:

```ruby
require 'otp/sms_otp_job'

class User < ActiveRecord::Base
  include OTP::ActiveRecord

  SMS_TEMPLATE = '%{otp} is your APP magic password 🗝️'

  def sms_otp
    OTP::SMSOTPJob.perform_later(
      phone_number,
      otp,
      SMS_TEMPLATE # <-- Optional text message template.
    ) if phone_number.present?
  end
end
```

You will have to provide your model with the phone number attribute if you
want to deliver the OTPs via SMS.

This job requires `aws-sdk-sns` gem to work. You will have to add it manually
and configure to use the correct keys. The SNS region is fetched from the
environment variable `AWS_SMS_REGION`.

### JWT for Active Record models

To add support for JWT to your models, use the `OTP::JWT::ActiveRecord` concern:

```ruby
class User < ActiveRecord::Base
  include OTP::JWT::ActiveRecord

  ...
end
```

This will provide two new methods which you can use to generate and verify JWT
tokens:
 * `User#from_jwt`
 * `User#to_jwt`

### JWT authorization

To add support for JWT to your controllers,
use the `OTP::JWT::ActionController` concern:

```ruby
class ApplicationController < ActionController::Base
  include OTP::JWT::ActionController

  private

  def current_user
    @jwt_user ||= User.from_jwt(request_authorization_header)
  end

  def current_user!
    current_user || raise('User authentication failed')
  rescue
    head(:unauthorized)
  end
end
```

The example from above includes helpers you can use interact with the
currently authenticated user or just use as part of `before_action` callback.

The `request_authorization_header` method is also provided by the concern and
allows you to customize from where the token is received. A query parameter
based alternative would look like this:

```ruby
class ApplicationController < ActionController::Base
  include OTP::JWT::ActionController

  private

  def current_user
    @jwt_user ||= User.from_jwt(params[:token])
  end

  ...
end
```

### JWT authentication

The `OTP::JWT::ActionController` concern provides support for handling the
authentication requests and token generation by using the `jwt_from_otp` method.

Here's an example of a tokens controller:

```ruby
class TokensController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    jwt_from_otp(user, params[:otp]) do |auth_user|
      # Let's update the last login date before we send the token...
      # auth_user.update_column(:last_login_at, DateTime.current)

      render json: { token: auth_user.to_jwt }, status: :created
    end
  rescue OTP::Errors::Invalid, OTP::Errors::Expired, OTP::Errors::UserNotFound => e
    render json: { errors: [e.message] }, status: :unauthorized
  end
end
```

The `jwt_from_otp` does a couple of things here:
 * It will try to authenticate the user you found by email and respond with
   a valid JWT token
 * It will try to schedule an email or SMS delivery of the OTP and it will
   respond with the 400 HTTP status
 * It will raise an exception if there's no user or the OTP is wrong

To change the behavior for the forbidden (403) responses, add this to an
initializer and configure on forbidden request handler:

```ruby
# config/initializers/otp-jwt.rb
OTP::JWT.configure do |config|
  config.on_forbidden_request = ->(controller) do
    controller.render json: { error: 'Invalid credentials' }, status: :forbidden
  end
end
```

The OTP delivery is handled by the `User#deliver_otp` method
and can be customized. By default it will call the `sms_otp` method and
if nothing is returned, it will proceed with the `email_otp` method.

### JWT Tokens

To help sign any sort of data, a lightweight JWT Token wrapper is provided.

Signing a payload will follow the pre-defined settings like the lifetime and
the encryption key. Decoding a token will validate any claims as well. Finally
there's a safe wrapper to help you with the JWT specific exceptions handling.

```ruby
require 'otp/jwt/token'

token = OTP::JWT::Token.sign(sub: 'my subject')
OTP::JWT::Token.decode(token) == {'sub' => 'my subject'}
OTP::JWT::Token.decode('bad token') == nil
```

## Rate Limiting

To prevent abuse, OTP and magic link requests are rate limited per user/email and per IP address. By default, a user or IP can only request 5 OTPs or magic links every 10 minutes. If the limit is exceeded, a 429 Too Many Requests error is returned.

## Error Codes & Standardized Responses

All error responses are standardized and include an error code and message. Example:

```json
{
  "error": {
    "code": "OTP_EXPIRED",
    "message": "The provided OTP has expired."
  }
}
```

| Code              | Message                                      |
|-------------------|----------------------------------------------|
| OTP_INVALID       | The provided OTP is invalid.                 |
| OTP_EXPIRED       | The provided OTP has expired.                |
| USER_NOT_FOUND    | The user was not found.                      |
| ACCOUNT_BLOCKED   | Your account is blocked. Please contact support. |
| OTP_SEND_FAILED   | Failed to send OTP.                          |
| RATE_LIMITED      | Too many requests. Please try again later.    |
| INVALID_MAGIC_LINK| Invalid magic link.                          |
| AUTH_FAILED       | Authentication failed.                       |

## Magic Link & OTP Replay Protection

- Magic links are single-use and expire after 15 minutes by default.
- OTPs are single-use and expire after use (counter-based). Account is locked after too many failed attempts.

## Development

After checking out the repo, run `bundle` to install dependencies.

Then, run `rake` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/stas/otp-jwt

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
