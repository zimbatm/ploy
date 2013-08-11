require 'securerandom'

module App

  # An ActiveRecord::Base extension for your models to use random ids instead
  # of incremental once. You'll thank me later once you want to partition
  # your data.
  #
  # Here is an example of a table that would work with this # extension:
  #
  #     create_table :accounts, id: false do |t|
  #          t.string :id, limit: 36, null: false
  #     end
  #     add_index :accounts, :id, unique: true
  module GeneratedID
    def self.included(base)
      base.primary_key = :id
      base.class_eval do
        before_create :set_key
      end
    end

    protected

    def set_key
      id = SecureRandom.random_bytes
                      .unpack("Q*")
                      .map{|s| s.to_s(32)}
                      .join
      write_attribute(:id, id)
    end
  end

end
