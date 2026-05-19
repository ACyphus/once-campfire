class AddSignupAgreementTimestampsToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :code_of_conduct_agreed_at, :datetime
    add_column :users, :minimum_age_attested_at,   :datetime
  end
end
