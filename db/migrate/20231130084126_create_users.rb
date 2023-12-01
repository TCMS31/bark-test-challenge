# frozen_string_literal: true

# Creates the users table with the unique index the model relies on to make
# email uniqueness a database guarantee rather than a validation-only one.
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :password_digest, null: false

      t.timestamps
    end
  end
end
