class CreateBlacklistedTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :otp_jwt_blacklisted_tokens do |t|
      t.string :jti, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :otp_jwt_blacklisted_tokens, :jti, unique: true
  end
end
