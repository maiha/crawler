require "./strategy/*"

module Crawl::Strategy
  var strategy : Strategy::Base

  # overrides to bind logger
  def strategy=(v : Strategy::Base)
    @strategy = v
    strategy.logger = logger
  end

  def execute(req : Request) : Response
    before_validate.each &.call(req)
    before_execute.each &.call(req)

    begin
      res = strategy.execute(req)
      return res
    ensure
      after_execute.each(&.call(req, res))
    end
  end
end
