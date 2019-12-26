module Crawl::PrefixLogging
  var prefix_logging : String

  {% for method in %w( debug info warn error fatal log ) %}
    def {{method.id}}(msg : String)
      if prefix = prefix_logging?
        msg = "#{prefix}#{msg}"
      end
      logger.{{method.id}}(msg)
    end
  {% end %}    
end
