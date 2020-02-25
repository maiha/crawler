class Crawl::Config < TOML::Config
  FILENAME = ".crawlrc"

  class Error < Exception; end

  var clue : String

  # base
  bool "verbose"
  bool "dryrun"
  bool "colorize"
  i32  "limit"
  str  "fields"
  str  "format"
  bool "force"

  # crawl
  str   "crawl/url"
  bool  "crawl/logging"

  i32   "crawl/page_max"
  str   "crawl/wait"
  i32   "crawl/retry_max"
  str   "crawl/retry_wait"
  
  f64   "crawl/dns_timeout"
  f64   "crawl/connect_timeout"
  f64   "crawl/read_timeout"

  str   "crawl/log_dir"
  str   "crawl/store_dir"
  str   "crawl/user_agent"

  # page
  str   "crawl/html"
  str   "crawl/next"

  def crawl_client : Crawl::Client
    client = Crawl::Client.new
    strategy = Crawl::Strategy::Libcurl.new
    {% for x in %w( dns_timeout connect_timeout read_timeout ) %}
      strategy.{{x.id}} = crawl_{{x.id}}?
    {% end %}
    client.strategy = strategy
    client.strategy.user_agent = crawl_user_agent?
    client
  end

  def table(field : String)
    # toml[field]?.must.cast(TOML::Table)
    # toml[field]?.as(TOML::Table)
    toml[field]?.as?(TOML::Table) || raise Error.new("invalid config: [#{field}] not found")
  end

  def extract?(name : String) : Hash(String, String)?
    table("extract")[name]?.try(&.must.cast(Hash(String, String)))
    # Underlying type from Union Types fails in Crystal.
    # table("extract")[name]?.try(&.as(Hash(String, String)))
  end

  def possible_extract_targets : Array(String)
    hash = table("extract")
    hash.each do |k, v|
      return hash.keys.sort if v.is_a?(Hash)
    end
    return Array(String).new
  end

  # callback for initialize
  def init!
  end

  def build_logger(path : String?) : Logger
    build_logger(self.toml["logger"]?, path)
  end

  def build_logger(hash, _path : String?) : Logger
    case hash
    when Nil
      return Logger.new(nil)
    when Array
      Pretty::Logger.new(hash.map{|i| build_logger(i, _path).as(Logger)})
    when Hash
      hint = hash["name"]?.try{|s| "[#{s}]"} || ""
      hash["path"] ||= _path || raise Error.new("logger.path is missing")
      logger = Pretty::Logger.build_logger(hash)
      logger.formatter = "{{mark}},[{{time=%H:%M}}] #{hint}{{message}}"
      return logger
    else
      raise Error.new("logger type error (#{hash.class})")
    end
  end

  def to_s(io : IO)
    max = @paths.keys.map(&.size).max
    @paths.each do |(key, val)|
      io.puts "  %-#{max}s = %s" % [key, val]
    end
  end

  private def pretty_dump(io : IO = STDERR)
    io.puts "[config] #{clue?}"
    io.puts to_s
  end
end

class Crawl::Config < TOML::Config
  def self.parse_file(path : String)
    super(path).tap(&.clue = path)
  end

  def self.empty
    parse("")
  end

  @@current : Crawl::Config = empty
  def self.current : Crawl::Config
    @@current
  end

  def self.current=(v) : Crawl::Config
    @@current = v
  end

  def self.sample
    parse(SAMPLE)
  end
end

Crawl::Config::SAMPLE = <<-EOF
[extract.json]
title = "css:div.r h3"

[crawl]
store_dir   = "."

url         = "https://www.google.com/search?q=crystal"
next        = "css:a.pn"
html        = "css:div.rc"

page_max    = 100
wait        = "1.0"
retry_max   = 3
retry_wait  = "3..5"

dns_timeout     = 3.0
connect_timeout = 5.0
read_timeout    = 300.0

user_agent      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100"

logging         = true

[[logger]]
path     = "STDOUT"
level    = "INFO"
format   = "{{mark}},[{{time=%H:%M:%S}}] {{message}}"
colorize = true

[[logger]]
path     = "crawl.log"
mode     = "w+"
level    = "DEBUG"
format   = "{{mark}},[{{time=%Y-%m-%d %H:%M:%S}}] {{message}}"
EOF
