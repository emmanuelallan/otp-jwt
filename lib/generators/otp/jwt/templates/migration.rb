class AddOtpJwtTo<%= table_name.camelize %> < ActiveRecord::Migration[8.0]
  def change
    add_column :<%= table_name %>, :otp_secret, :string
    add_column :<%= table_name %>, :otp_counter, :integer, default: 0
    add_column :<%= table_name %>, :otp_attempts, :integer, default: 0
    add_column :<%= table_name %>, :locked_at, :datetime
    add_column :<%= table_name %>, :expire_jwt_at, :datetime
    
    add_index :<%= table_name %>, :otp_secret
  end
end
