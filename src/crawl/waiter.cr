record Crawl::Waiter,
  range : Range(Float64, Float64) do

  def wait
    sec = rand(@range)
    sleep(sec) if sec > 0
  end

  def self.new(range : String)
    new(Str2xxx.str2range_float(range))
  end
end
