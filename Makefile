SHELL = /bin/zsh
.SHELLFLAGS = -o pipefail -c

export LC_ALL=C
export UID = $(shell id -u)
export GID = $(shell id -g)

WARNINGS := none

DYNAMIC_BUILD := crystal build src/cli/bin/crawler.cr
STATIC_BUILD  := docker-compose run --rm static shards build --link-flags "c /v/libcurl.a"

# TODO: static build (currently fails)
.PHONY : crawler
crawler:
	shards build crawler

.PHONY : dynamic
dynamic:
	$(DYNAMIC_BUILD) -o $@ --warnings $(WARNINGS)

# static build
# Invalid memory access (signal 11) at address 0x63
# [0x7f998f2d08bd] _nss_files_gethostbyname4_r +173
.PHONY : release
release:
	$(STATIC_BUILD) crawler --release

download:
	wget https://filmarks.com/list/vod/netflix

.PHONY : test
test: spec

.PHONY : spec
spec:
	crystal spec -v --fail-fast

.PHONY : proto
proto:
	@mkdir -p src/proto
	protoc -I proto --crystal_out src/proto proto/*.proto
#PROTOBUF_NS=Proto::Crawl protoc -I proto/crawl --crystal_out src/proto/crawl proto/crawl/*.proto

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1)
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')

.PHONY : version
version:
	@if [ "$(VERSION)" = "" ]; then \
	  echo "ERROR: specify VERSION as bellow. (current: $(CURRENT_VERSION))";\
	  echo "  make version VERSION=$(GUESSED_VERSION)";\
	else \
	  sed -i -e 's/^version: .*/version: $(VERSION)/' shard.yml ;\
	  sed -i -e 's/^    version: [0-9]\+\.[0-9]\+\.[0-9]\+/    version: $(VERSION)/' README.md ;\
	  echo git commit -a -m "'$(COMMIT_MESSAGE)'" ;\
	  git commit -a -m 'version: $(VERSION)' ;\
	  git tag "v$(VERSION)" ;\
	fi

.PHONY : bump
bump:
	make version VERSION=$(GUESSED_VERSION) -s

