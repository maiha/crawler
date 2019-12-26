require "./KVS.pb"

struct KVS
  def to_s(io : IO)
    time = at.try(&.time.to_s("%F")) || "---"
    text = val.try(&.gsub(/<.*?>/,"").strip[0..30])
    io << "[%s] %s: %s" % [time, key, text]
  end

  def inspect(io : IO)
    array = Array(Array(String)).new
    to_hash.each do |k,v|
      array << [k.to_s, v.inspect]
    end
    io << Pretty.lines(array, delimiter: ": ").gsub(/\s+$/, "")
  end
end
