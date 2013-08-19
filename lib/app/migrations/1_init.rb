class Init < ActiveRecord::Migration
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
    #
    create_table :applications, id: false do |t|
      t.string :id, limit: 36, null: false

      t.string :name, null: false

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :applications, :id, unique: true
    add_index :applications, :name, unique: true

    create_table :slugs, id: false do |t|
      t.string :id, limit: 36, null: false
      t.string :application_id, limit: 36, null: false

      t.string :build_id, null: false
      t.string :commit_id, limit: 40, null: false
      t.string :branch, null: false

      t.string :checksum
      
      t.string :url, null: false

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :slugs, :id, unique: true


    create_table :providers, id: false do |t|
      t.string :id, limit: 36, null: false

      t.string :name
      t.binary :config

      t.string :ssh_private_key, limit: 2048
      t.string :ssh_public_key, limit: 512

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :providers, :id, unique: true


    create_table :targets, id: false do |t|
      t.string :id, limit: 36, null: false

      t.string :role
      t.string :env
      t.string :application_id, limit: 36, null: false
      t.string :provider_id, limit: 36, null: false
      t.string :slug_id, limit: 36 #, null: false
      t.timestamp :deployed_at

      t.binary :config

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :targets, :id, unique: true
    #add_index :targets, [:role, :env, :application_id, :provider_id], unique: true

    create_table :deploys do |t|
      t.string :target_id, limit: 36, null: false
      t.string :slug_id, limit: 36, null: false

      t.timestamps
    end

    create_table :builds, id: false do |t|
      t.string :id, null: false

      t.string :application_id, limit: 36, null: false
      t.string :commit_id, limit: 40, null: false
      t.string :branch, null: false

      t.string :state, null: false

      t.timestamps
    end
    add_index :builds, :id, unique: true
    add_index :builds, [:application_id, :state]

  end
end
