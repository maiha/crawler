require "../cli"

class Cli::Main
  include Opts
  include GlobalHelper

  {% begin %}
  TARGET_TRIPLE = "{{`crystal -v | grep x86_64 | cut -d: -f2`.strip}}"
  {% end %}

  CONFIG_FILE = Crawl::Config::FILENAME
  
  USAGE = <<-EOF
    usage: {{program}} [options] <commands>

    options:
    {{options}}

    commands:
      #{Cmds.names.sort.join(", ")}
    EOF

  option config_path  : String?, "-K <config>", "Crawl config file (default: '~/.crawlrc')", nil

  option fields  : String?, "-f <fields>", "Select only these fields", nil
  option limit   : Int32?, "-l <limit>", "Select only first limit records", nil
  option format  : String?, "-F <format>", "Specify format", nil
  option force   : Bool  , "--force", "Force option", false
  option dryrun  : Bool  , "-n", "Dryrun mode", false
  option debug   : Bool  , "-d", "Set logger level to DEBUG", false
  option verbose : Bool  , "-v", "Verbose output", false
  option nocolor : Bool  , "--no-color", "Disable colored output", false
  option version : Bool  , "--version", "Print the version and exit", false
  option help    : Bool  , "--help"   , "Output this help and exit" , false

  var cmd : Cmds::Cmd
  var config : Crawl::Config

  def run
    # setup
    self.config = load_config
    config.verbose  = verbose
    config.debug    = debug
    config.dryrun   = dryrun
    config.colorize = !nocolor
    config.force    = force
    config.limit    = limit.try(&.to_i32)
    config.fields   = fields
    config.format   = format
    config.init!

    Crawl::Config.current = config

    # execute
    (self.cmd = Cmds[args.shift?.to_s].new).run(args)
  end

  private def load_config : Crawl::Config
    # When the user specifies the file name
    if path = config_path
      # The error is left to Config when the specified file doesn't exist
      return Crawl::Config.parse_file(path)
    end

    # Scan all parent directories up to "/"
    dir = File.real_path("./")
    while !dir.empty?
      if config = load_config?(dir)
        return config
      end
      break if dir == "/"
      dir = File.expand_path(File.join(dir, ".."))
    end      

    return load_config?("~/") || Crawl::Config.empty
  end

  private def load_config?(dir : String) : Crawl::Config?
    path = File.expand_path(File.join(dir, CONFIG_FILE))
    if File.exists?(path)
      Crawl::Config.parse_file(path)
    else
      nil
    end
  end

  private def pretty_tasks(cmd, prefix)
    array = cmd.class.usages.map{|help| help.split(/\s*#\s*/, 2)}
    Pretty.lines(array, delimiter: "  # ").chomp.split(/\n/).map{|line|
      "%s%s %s %s" % [prefix, PROGRAM_NAME, cmd.class.cmd_name, line.strip]
    }.join("\n")
  end

  def on_error(err)
    case err
    when Cmds::Finished
      exit 0
    when Crawl::Config::Error, TOML::Config::NotFound
      STDERR.puts red("ERROR: #{err}")
      exit 1
    when Cmds::ArgumentError
      STDERR.puts red(err.to_s)
      STDERR.puts cmd.class.pretty_usage(prefix: " ")
      exit 2
    when Cmds::CommandNotFound
      STDERR.puts show_usage
      exit 3
    when Cmds::TaskNotFound
      task_names = cmd.class.task_names
      STDERR.puts red("ERROR: Task Not Found (current: '#{err.name}')")
      STDERR.puts "[possible tasks]"
      STDERR.puts "  %s" % task_names.join(", ")
      STDERR.puts
      STDERR.puts "[examples]"
      STDERR.puts pretty_tasks(cmd, prefix: "  ")
      exit 4
    when Crawl::Dryrun
      STDERR.puts err.inspect
      exit 10
    when Crawl::ReachedMaxPage
      cmd.logger.info err.to_s
    when Crawl::Denied, Crawl::Error
      STDERR.puts red(err.to_s)
      exit 20
    when Errno
      STDERR.puts red(err.to_s)
      exit 91
#    when Cmds::Abort
#      STDERR.puts red(Pretty.error(err).message)
#      cmd.logger.error "ERROR: #{err}"
#      exit 99
#    when Cmds::Halt
#      cmd.logger.warn err.to_s
#      STDERR.puts red(err.to_s)
#      exit 100
    else
      STDERR.puts red(Pretty.error(err).message)
      cmd.logger.error "ERROR: #{err} (#{err.class.name})"
      cmd.logger.error(err.inspect_with_backtrace)
      STDERR.puts red(Pretty.error(err).where.to_s) # This may kill app
      exit 255
    end
  end

  def show_version
    "#{PROGRAM} #{VERSION} #{TARGET_TRIPLE} crystal-#{Crystal::VERSION} #{String.new(LibCurl.curl_version)}"
  end
end

Cli::Main.run
