# frozen_string_literal: true

class CreateAuthentications < ActiveRecord::Migration[5.2]
  def change
    create_table :authentications do |t|
      t.references :user, foreign_key: true
      t.string :type, null: false

      t.timestamps
    end
  end
end
