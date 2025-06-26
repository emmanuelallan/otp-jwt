class CreateOtpJwtBlacklistedTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :otp_jwt_blacklisted_tokens do |t|
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :otp_jwt_blacklisted_tokens, :token, unique: true
  end
end
