## Generated from KVS.proto
require "protobuf"


struct KVS
  include Protobuf::Message
  
  contract_of "proto2" do
    optional :key, :string, 1
    optional :val, :string, 2
    optional :at, Datetime, 3
  end
end
