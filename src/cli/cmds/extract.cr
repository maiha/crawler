Cmds.command "extract" do
  usage "run   <name>             # extract data from html by config[extract.<name>]"
  usage "test  <file> <pattern>   # extract data from <file> by <pattern>"
  usage "clean <name>             # delete extracted files"

  var logger : Logger = config.build_logger(path: nil)

  task "run" do
    name = arg1
    process(name)
  end

  task "test" do
    file = arg1
    File.exists?(file) || abort "file not found: #{file.inspect}"

    lookup = Crawl::Lookup.parse?(arg2) || abort "invalid pattern: [#{arg2.inspect}]"
    do_test(path: Path[file], lookup: lookup)
  end

  task "clean" do
    name  = arg1
    house = kvs_house(name)
    house.clean
  end

  protected def process(extract_name)
    lookups = build_lookups(extract_name, hint: "[extract.#{extract_name}]")
    house   = kvs_house(extract_name)

    logger.debug "%s: lookups: %s" % [extract_name, lookups]
    
    dsts = Array(KVS).new
    html_house.load.each_with_index do |src, i|
      item_no = i+1
      if html = src.val
        myhtml = Myhtml::Parser.new(html)
        hash = Hash(String, String).new
        lookups.each do |key, lookup|
          begin
            hash[key] = apply_lookup(lookup, myhtml, html)
          rescue err : Must::MatchError
            if config.verbose?
              hint = "while extracting [#{extract_name}##{item_no}] key=#{key},#{lookup}\n#{html}"
              raise Crawl::Error.new("#{err}\n#{hint}")
            else
              raise err
            end
          end

          hash.delete(key) if hash[key]?.to_s.empty?
        end
        dsts << KVS.new(key: src.key, val: hash.to_json, at: src.at)
        logger.debug "%s: %s" % [item_no, dsts.last.val]
      end
    end
    house.write(dsts)
    logger.info "%s: %d records" % [extract_name, house.count]

  rescue err
    logger.error "%s: %s" % [extract_name, err.inspect_with_backtrace]
    raise err
  end

  protected def do_test(path : Path, lookup : Crawl::Lookup)
    html   = File.read(path)
    myhtml = Myhtml::Parser.new(html)
    value  = apply_lookup(lookup, myhtml, html)

    puts "lookup: #{lookup.to_s.inspect}"
    puts "value : #{value.inspect}"
  end

  private def apply_lookup(lookups : Array(Crawl::Lookup), myhtml, html) : String
    lookups.each do |lookup|
      html = apply_lookup(lookup, myhtml, html)
    end
    return html
  end
  
  private def apply_lookup(lookup : Crawl::Lookup, myhtml, html) : String
    case lookup
    when Crawl::Lookup::CSS
      myhtml.css(lookup.path).first?.try(&.inner_text).to_s
    when Crawl::Lookup::REGEX
      html.must.match(lookup.regex, "$1")
    when Crawl::Lookup::STRIP
      html.strip
    else
      raise Crawl::Error.new("BUG: #{lookup.class} is not implemented yet")
    end
  end

  private def extract_mapping(name : String) : Hash(String, Array(String))
    config.extract?(name) || raise Crawl::Config::Error.new("no 'extract.#{name}' field in config")
  end
  
  private def build_lookups(name : String, hint : String)
    lookups = Hash(String, Array(Crawl::Lookup)).new

    extract_mapping(name).each do |key, val|
      lookups[key] = Crawl::Lookup.parse?(val) || raise Crawl::Config::Error.new("invalid pattern '%s' in '%s %s'" % [val, hint, key])
    end
    return lookups
  end
end

