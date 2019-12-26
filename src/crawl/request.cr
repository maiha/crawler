class Crawl::Request
  def self.get(uri)
    new(Method::GET, uri)
  end

  enum Method
    GET
    POST
    PUT
    HEAD
    DELETE
    PATCH
  end

  var uri    : URI
  var method : Method
  var path   : String
  var data   : Hash(String, String) = Hash(String, String).new # query parameters
  var form   : Hash(String, String) = Hash(String, String).new # form parameters

  def initialize(@method, @uri)
  end

  protected def build_request_path
    return path if data.empty?

    params = Array(String).new
    data.each do |key, value|
      params << "%s=%s" % [URI.escape(key), URI.escape(value)]
    end
    delimiter = path.includes?("?") ? "&" : "?"
    path + delimiter + params.join("&")
  end
  
  private def to_query_string(hash : Hash)
    HTTP::Params.build do |form_builder|
      hash.each do |key, value|
        form_builder.add(key, value)
      end
    end
  end

  def to_s(io : IO)
    io << http.method << ' ' << http.path
  end
  
  def url : String
    uri.to_s
  end

  # "GET http://..."
  def to_s(io : IO)
    io << url
  end
end
