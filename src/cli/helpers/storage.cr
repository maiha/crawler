abstract class Cmds::Cmd
  # config
  var store_dir : String = config.crawl_store_dir

  # storage
  var http_house = Protobuf::House(HttpCall).new(File.join(store_dir, "HttpCall"), logger: logger)
  var html_house = kvs_house("html")

  # internal constants
  META_DONE = "done"

  private def kvs_house(name)
    if name !~ /\A[a-z0-9]+\Z/
      raise Crawl::Config::Error.new("invalid kvs name: '#{name}'")
    end
    Protobuf::House(KVS).new(File.join(store_dir, "#{name}/KVS"), schema: KVS_PROTO, logger: logger)
  end

  KVS_PROTO = <<-EOF
    syntax = "proto2";

    message Datetime {
      required string value = 1; 
    }

    message KVS {
      optional string   key = 1;
      optional string   val = 2;
      optional Datetime at  = 3;
    }
    EOF
end
