class BaseTables < ActiveRecord::Migration
  def up
    create_table :accounts, id: false do |t|
      t.string :id, limit: 36, null: false

      # Auth
      t.string :email, null: false
      t.string :hashed_password, null: false

      # Human details
      t.string :full_name

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :accounts, :id, unique: true
    add_index :accounts, :created_at, order: 'desc'

    create_table :api_keys, id: false do |t|
      t.string :id, limit: 36, null: false
      t.string :account_id, limit: 36
      t.boolean :active, default: true

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :api_keys, :id, unique: true
    #add_index :api_keys, [:account_id, :created_at], order: 'desc'

    create_table :applications, id: false do |t|
      t.string :id, limit: 36, null: false

      t.string :name, null: false

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :applications, :id, unique: true
    add_index :applications, :name, unique: true
  end
end
