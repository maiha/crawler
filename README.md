# crawler [![Build Status](https://travis-ci.org/maiha/crawler.svg?branch=master)](https://travis-ci.org/maiha/crawler)

Highly customizable web crawler
- **fast** : Native code with libcurl
- **simple** : Just edit config
- **flexible** : Extract data by CSS and Regex
- **safe** : Detect infinite loop
- **tracable** : All HTTP transfered data are stored

## Installation

##### Static Binary is ready for x86_64 linux

- https://github.com/maiha/crawler/releases

## Usage

1. edit config
2. receive html
3. extract data

##### 1. edit config

For the first time, `config generate` may help you.

```console
$ crawler config generate
$ vi .crawlrc
```

```toml
[extract.json]
title = "css:div.r h3"
name  = ["css:p.name", "strip:"]

[crawl]
url      = "https://www.google.com/search?q=crystal"
next     = "css:a.pn"
html     = "css:div.rc"
page_max = 2
```

This means
- Visits initial url `config:crawl.url`
- Extracts html part `config:crawl.html` and stores in local
- Follows next url `config:crawl.next` if page limit doesn't exceed `config:crawl.page_max`

##### 2. receive html

```console
$ crawler recv html
```

##### 3. extract data

```console
$ crawler extract json
$ crawler pb list json -f val
{"title":"Crystal"}
...
```

## Development

- [crystal](http://crystal-lang.org/) 0.33.0

##### for dynamic binary
```console
$ make dynamic
```

##### for static binary

needs `libcurl.a`.

```console
$ make static
```

## Contributing

1. Fork it (<https://github.com/maiha/crawler/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) - creator and maintainer
