class DeployTables < ActiveRecord::Migration
  def up
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
  end
end
