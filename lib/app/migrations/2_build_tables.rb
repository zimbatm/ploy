class BuildTables < ActiveRecord::Migration
  def up
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

    create_table :slugs, id: false do |t|
      t.string :id, limit: 36, null: false

      t.string :application_id, limit: 36, null: false
      t.string :build_id, null: false
      t.string :commit_id, limit: 40, null: false
      t.string :branch, null: false

      t.string :checksum
      
      t.string :url, null: false

      t.timestamps
    end
    add_index :slugs, :id, unique: true
  end
end
