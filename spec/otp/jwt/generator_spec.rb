require 'spec_helper'
require 'rails/generators'
require 'generators/otp/jwt/user_generator'
require 'generators/otp/jwt/install_generator'

RSpec.describe 'OTP::JWT Generators', type: :generator do
  before(:each) do
    @destination = File.expand_path("../../../../tmp/generator_test", __FILE__)
    FileUtils.rm_rf(@destination)
    FileUtils.mkdir_p(@destination)
  end
  
  let(:table_name) { 'users' }

  it 'creates a migration file' do
    run_generator(OTP::JWT::Generators::UserGenerator, [table_name])
    migration = Dir[File.join(@destination, 'db/migrate/*_add_otp_jwt_to_users.rb')].first
    expect(migration).to be_present
    content = File.read(migration)
    expect(content).to include('add_column :users, :otp_secret, :string')
  end

  it 'injects concern into user model' do
    user_model = File.join(@destination, 'app/models/user.rb')
    FileUtils.mkdir_p(File.dirname(user_model))
    File.write(user_model, "class User < ApplicationRecord\nend\n")
    run_generator(OTP::JWT::Generators::UserGenerator, [table_name])
    content = File.read(user_model)
    expect(content).to include('include OTP::JWT::Concerns::User')
  end

  it 'creates an initializer file' do
    run_generator(OTP::JWT::Generators::InstallGenerator)
    initializer = File.join(@destination, 'config/initializers/otp_jwt.rb')
    expect(File).to exist(initializer)
    content = File.read(initializer)
    expect(content).to include('OTP::JWT.configure')
  end
end 