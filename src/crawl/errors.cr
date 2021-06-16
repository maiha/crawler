# recoverable error (5xx)
class Crawl::Error < Exception
end

class Crawl::ReachedMaxPage < Crawl::Error
end

class Crawl::Dryrun < Crawl::Error
end

# fatal error (bug)
class Crawl::Fatal < Crawl::Error
end

# unrecoverable error (4xx)
class Crawl::Denied < Crawl::Fatal
end
