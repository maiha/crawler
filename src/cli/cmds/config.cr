Cmds.command "config" do
  task "generate" do
    check_writable!
    File.write(path, Crawl::Config::SAMPLE)
  end

  private def check_writable!
    return true if ! File.exists?(path)
    return true if config.force?

    cmd = "%s config generate --force" % PROGRAM_NAME
    raise Crawl::Error.new("Config already exists. Try with '--force' option to overwrite it.\n  #{cmd}")
  end

  private def path
    Crawl::Config::FILENAME
  end
end

