## Generated from Content.proto
require "protobuf"


struct Content
  include Protobuf::Message
  
  contract_of "proto2" do
    optional :key, :string, 1
    optional :val, :string, 2
    optional :at, Datetime, 3
  end
end
