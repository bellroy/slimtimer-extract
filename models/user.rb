class User
  include DataMapper::Resource

  property :id, Integer, :key => true
  property :username, String
  property :name, String
end
