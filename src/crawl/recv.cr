class Crawl::Recv
  include Crawl::PrefixLogging

  # input
  var client     : Client
  var url        : String
  var retry_wait : Waiter
  var retry_max  : Int32
  var logger     : Logger

  var clue       : String
  
  # output
  var res : Response

  # internal
  var try_myhtml : Failure(Myhtml::Parser) | Success(Myhtml::Parser) = Try(Myhtml::Parser).try{ Myhtml::Parser.new(res.body) }

  def initialize(@client, @url, @retry_max, @retry_wait, @logger)
    self.prefix_logging = "[recv] "
  end

  def execute!
    (0..retry_max).each do |retry_cnt|
      begin
        @res = client.get(url)
        res.success!
        return nil
      rescue err : Crawl::Fatal
        raise err
      rescue err
        logger.warn "recv: error: #{err}"
        retry_wait.wait
      end
    end
    raise Crawl::Fatal.new("exceeded retry max(%d)" % retry_max)
  end

  def css1?(css, attr = nil) : String?
    array = myhtml.css(css)
    debug "css:%s => %d elements" % [css.inspect, array.size]

    array.each do |node|
      if attr
        # Myhtml::Node(:a, {"rel" => "next", "href" => "/list"})
        v = node.attributes[attr]?
        debug "  node[%s] => %s" % [attr, v.inspect]
        return v
      else
        return node.to_html
      end
      break
    end
    return nil
  end

  def nodes(lookup : Lookup?)
    case lookup
    when Lookup::CSS
      css = lookup.path
      array = myhtml.css(css)
      debug "css:%s => %d elements" % [css.inspect, array.size]
      return array
    else
      raise Crawl::Config::Error.new("next_url doesn't support lookup: '#{lookup}'")
    end
  end

  def next_url?(lookup : Lookup?) : String?
    case lookup
    when Lookup::CSS
      if href = css1?(lookup.path, attr: "href")
        return resolve_url(href)
      end
    when Nil
    when Lookup
      raise Crawl::Config::Error.new("next_url doesn't support lookup: '#{lookup}'")
    end
    return nil
  end

  def resolve_url(href : String) : String
    URI.parse(url).resolve(href).to_s
  end

  def myhtml
    try_myhtml.get
  end
end
