require "./callback"
require "./strategy"
require "./request"
require "./response"

module Crawl
  class Client
    include Crawl::Callback
    include Crawl::Strategy

    var logger : Logger = Logger.new(nil)

    def initialize(@logger : Logger? = nil)
      libcurl!
      self.logger = logger                # set loggers on related objects
    end

    ######################################################################
    ### shortcuts for Crawl class

    def libcurl!
      self.strategy= Crawl::Strategy::Libcurl.new
    end

    def logger=(v : Logger)
      @logger = v
      strategy.logger = v
    end
    
    ######################################################################
    ### API methods

    # See ./api/*.cr
    
    ######################################################################
    ### HTTP methods
    
    def get(path : String, data = {} of String => String) : Response
      req = Request.get(URI.parse(path))
      req.data.merge!(data)
      execute(req)
    end

  end
end
