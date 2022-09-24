abstract class Crawl::Lookup
  class CSS < Lookup
    var path : String

    def initialize(@path)
    end

    def to_s(io : IO)
      io << "css:#{path}"
    end
  end

  class REGEX < Lookup
    var regex : Regex

    def initialize(@regex)
    end

    def to_s(io : IO)
      io << "regex:#{regex.source}"
    end
  end

  class STRIP < Lookup
    def to_s(io : IO)
      io << "strip:"
    end
  end

  def self.parse?(buf : Array(String)?) : Array(Lookup)?
    if buf
      buf.map{|b| parse(b)}
    else
      nil
    end
  end

  def self.parse?(buf : String?) : Lookup?
    if buf
      parse(buf)
    else
      nil
    end
  end
  
  def self.parse(buf : String) : Lookup
    case buf
    when /^css:(.*)/
      CSS.new($1.strip)
    when /^regex:(.*)/
      REGEX.new(/#{$1.strip}/)
    when /^strip:$/
      STRIP.new
    else
      raise Crawl::Config::Error.new("invalid pattern '%s' (possible: css, regex)" % buf)
    end    
  end
end
