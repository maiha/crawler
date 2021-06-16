Cmds.command "recv" do
  usage "run               # fetch htmls"
  usage "clean             # delete fetched htmls"
  usage "clean             # delete fetched htmls"

  var logger : Logger = config.build_logger(path: nil)

  var visited_urls  = Set(String).new

  # config
  var html_lookup : Crawl::Lookup
  var next_lookup : Crawl::Lookup
  var retry_max   : Int32 = config.crawl_retry_max

  var retry_wait = Crawl::Waiter.new(config.crawl_retry_wait? || "3..5")
  var api_wait   = Crawl::Waiter.new(config.crawl_wait? || "1")

  # internal
  var page_cnt     : Int32  = 0
  var page_max     : Int32  = config.crawl_page_max
  var current_url  : String
  var previous_url : String

  def before
    @html_lookup = Crawl::Lookup.parse?(config.crawl_html)
    @next_lookup = Crawl::Lookup.parse?(config.crawl_next)
  end
  
  task "clean" do
    http_house.clean    
    html_house.clean    
  end
  
  task "run" do
    self.current_url = startup_url?

    while url = current_url?
      ensure_page_max!
      recv = fetch(url)
      process(recv)

      self.previous_url = current_url?
      # set url to instance directly for the case of nil
      @current_url = compute_next_url(recv)
    end

    html_house.meta[META_DONE] = Pretty::Time.now.to_s
  end

  protected def ensure_page_max!
    if page_cnt >= page_max
      raise Crawl::ReachedMaxPage.new("Reached the page_max: #{page_max}")
    end
  end
  
  protected def fetch(url : String) : Crawl::Recv
    recv = Crawl::Recv.new(new_client, url: url, retry_max: retry_max, retry_wait: retry_wait, logger: logger)
    recv.execute!
    return recv
  end

  protected def process(recv : Crawl::Recv)
    at    = Datetime.new(Pretty::Time.now)
    array = recv.nodes(html_lookup)

    htmls = Array(KVS).new
    array.each_with_index do |node, i|
      key = "%s#%d" % [recv.url, i]
      val = node.to_html
      htmls << KVS.new(key: key, val: val, at: at)
    end
    html_house.save(htmls)
  end

  protected def compute_next_url(recv : Crawl::Recv) : String?
    url = recv.next_url?(next_lookup?)
    html_house.checkin(url)
    debug "found next url: %s" % [url] if url
    return url
  end
  
  private def on_success(req : Crawl::Request, res : Crawl::Response)
    @page_cnt = page_cnt + 1
  end

  private def new_client : Crawl::Client
    client = config.crawl_client
    client.logger              = logger
    client.strategy.user_agent = config.crawl_user_agent?
    client.strategy.referer    = previous_url?
    client.before_execute {|req| before_execute(req) }
    client.after_execute  {|req, res| after_execute(req, res) }
    return client
  end

  private def before_execute(req)
    if visited_urls.includes?(req.url)
      raise Crawl::Fatal.new("loop detected: this url has been visited. url=%s" % req.url)
    end

    if page_cnt >= config.crawl_page_max
      raise Crawl::Fatal.new("exceeded page max(%d)" % config.crawl_page_max)
    end
    
    url = req.url
    if url.includes?(" ")
      raise "[BUG] url contains spaces: #{url}"
    end

    if page_cnt > 0
      api_wait.wait
    end

    logger.info "open: #{url}"
  end

  private def after_execute(req, res)
    write_http_call(req, res)
    if r = res
      logger.info "  %s => %s" % [r.code, Pretty.bytes(r.body.size)]

      if r.success?
        on_success(req, r)
      end
    end
    if res.try{|r| r.success? || r.client_error? }
      visited_urls << req.url
      # logger.debug visited_urls.inspect
    end
  end
  
  private def write_http_call(req : Crawl::Request, res : Crawl::Response?)
    pb = HttpCall.new(
      url: req.url,
      method: req.method.to_s,
      header: "",               # TODO: how to get request header in libcurl
      body: "",                 # TODO: how to get request body in libcurl
      requested_at: Datetime.new(res.try(&.requested_at) || Pretty.now),
    )
    if res
      pb.responsed_at = Datetime.new(res.responsed_at)
      pb.status       = res.code
      pb.res_header   = res.headers.to_h.to_json
      pb.res_body     = res.body
    end
    http_house.save(pb)
  end

  private def startup_url?(logging : Bool = true) : String?
    # if done, nothing to do
    if html_house.meta[META_DONE]?
      debug "startup_url: found meta[done]. nothing to do." if logging
      return nil
    end

    # if suspended job is found, return it
    if url = html_house.resume?
      info "startup_url: #{url} (resumed)" if logging
      return url
    end

    # if nothing finished and no current job, return initial url
    url = config.crawl_url
    info "startup_url: #{url}" if logging
    return url
  end
end

