require "./HttpCall.pb"

struct HttpCall
  def uri
    URI.parse(url)
  end

  def to_s(io : IO)
    code = status || "???"
    io << "[%s] %s %s" % [code, method, url]
  end

  def inspect(io : IO)
    array = Array(Array(String)).new
    to_hash.each do |k,v|
      array << [k.to_s, v.inspect]
    end
    io << Pretty.lines(array, delimiter: ": ").gsub(/\s+$/, "")
  end
end
