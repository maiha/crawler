# crawler

web crawler

## Installation

- [crystal](http://crystal-lang.org/) 0.31.1
```console
$ make
```

## Usage

```console
$ crawler config generate
$ vi .crawlrc
```

```toml
[extract.json]
title = "css:div.r h3"

[crawl]
url      = "https://www.google.com/search?q=crystal"
next     = "css:a.pn"
html     = "css:div.rc"
page_max = 2
```

```console
$ crawler recv run
$ crawler extract json
$ crawler pb list json -f val
{"title":"Crystal"}
...
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/maiha/crawler/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) - creator and maintainer
