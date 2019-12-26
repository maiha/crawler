Cmds.command "extract" do
  var logger : Logger = config.build_logger

  def run
    if name = task_name?
      process(name)
    else
      logger.info "possible: %s" % config.possible_extract_targets.join(", ")
    end
  end

  protected def process(extract_name)
    lookups = build_lookups(extract_name, hint: "[extract.#{extract_name}]")
    house   = kvs_house(extract_name)

    dsts = Array(KVS).new
    html_house.load.each_with_index do |src, i|
      item_no = i+1
      if html = src.val
        myhtml = Myhtml::Parser.new(html)
        hash = Hash(String, String).new
        lookups.each do |key, lookup|
          begin
            case lookup
            when Crawl::Lookup::CSS
              hash[key] = myhtml.css(lookup.path).first?.try(&.inner_text).to_s
            when Crawl::Lookup::REGEX
              hash[key] = html.must.match(lookup.regex, "$1")
            else
              raise Crawl::Error.new("BUG: #{lookup.class} is not implemented yet")
            end
          rescue err : Must::MatchError
            if config.verbose?
              hint = "while extracting [#{extract_name}##{item_no}] key=#{key},#{lookup}\n#{html}"
              raise Crawl::Error.new("#{err}\n#{hint}")
            else
              raise err
            end
          end
        end
        dsts << KVS.new(key: src.key, val: hash.to_json, at: src.at)
      end
    end
    house.write(dsts)
    logger.info "%s: %d records" % [extract_name, house.count]
  end

  private def extract_mapping(name : String)
    config.extract?(name) || raise Crawl::Config::Error.new("no 'extract.#{name}' field in config")
  end
  
  private def build_lookups(name : String, hint : String)
    lookups = Hash(String, Crawl::Lookup).new

    extract_mapping(name).each do |key, val|
      lookups[key] = Crawl::Lookup.parse?(val) || raise Crawl::Config::Error.new("invalid pattern '%s' in '%s %s'" % [val, hint, key])
    end
    return lookups
  end
end

