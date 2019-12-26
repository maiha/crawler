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

  def self.parse?(buf : String?) : Lookup?
    case buf
    when /^css:(.*)/
      CSS.new($1.strip)
    when /^regex:(.*)/
      REGEX.new(/#{$1.strip}/)
    when String
      raise Crawl::Config::Error.new("invalid pattern '%s' (possible: css, regex)" % buf)
    else
      nil
    end    
  end
end
