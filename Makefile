export LC_ALL=C
export UID = $(shell id -u)
export GID = $(shell id -g)

WARNINGS := none

DYNAMIC_BUILD := docker-compose run --rm static shards build
STATIC_BUILD  := docker-compose run --rm static shards build --link-flags "-static /v/libcurl.a"

.PHONY : compile
compile:
	crystal build -o bin/crawler src/cli/bin/crawler.cr --warnings $(WARNINGS)

.PHONY : dynamic
dynamic:
	$(DYNAMIC_BUILD) crawler

.PHONY : static
static:
	$(STATIC_BUILD) crawler

.PHONY : release
release:
	$(STATIC_BUILD) crawler --release

.PHONY : console
console:
	docker-compose run static bash

.PHONY : ci
ci: spec dynamic

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

