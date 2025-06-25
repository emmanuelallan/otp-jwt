class AddOtpAttemptTrackingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_attempts, :integer, default: 0
    add_column :users, :locked_at, :datetime
  end
end
