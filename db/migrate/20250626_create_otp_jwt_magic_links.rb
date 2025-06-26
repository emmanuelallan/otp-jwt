class CreateOtpJwtMagicLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :otp_jwt_magic_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :otp_jwt_magic_links, :token, unique: true
  end
end
