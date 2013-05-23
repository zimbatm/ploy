# Used to serialize ActiveRecord field that should contain a {} Hash.
class HashSerializer
  # Size of mysql fields
  TINYBLOB_FIELD = (2**8) - 1
  BLOB_FIELD = (2**16) - 1
  MEDIUMBLOB_FIELD = (2**24) - 1
  LONGBLOB_FIELD = (2**32) - 1

  class << self
    alias of new
  end

  class TooLarge < StandardError; end

  def initialize(max_size = BLOB_FIELD)
    @max_size = max_size
  end

  # Returns an array of strings
  def load(serialized_data)
    return {} if serialized_data.nil?
    MultiJson.load(serialized_data)
  end

  def dump(hash_data)
    hash_data = hash_data.to_h if hash_data.respond_to?(:to_h)
    return nil unless hash_data.kind_of?(Hash)

    data = MultiJson.dump(hash_data)
    if data.bytesize > @max_size
      raise TooLarge, "Data is too large to be serialized"
    end
    data
  end
end