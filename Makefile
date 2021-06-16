SHELL=/bin/bash

.SHELLFLAGS = -o pipefail -c

all: crawler-dev

######################################################################
### compiling

# for mounting permissions in docker-compose
export UID = $(shell id -u)
export GID = $(shell id -g)

COMPILE_FLAGS=
LINK_FLAGS=--link-flags "-static -lcurl -lnghttp2 -lidn2 -lssl -lcrypto -lz"
BUILD_TARGET=

.PHONY: build
build:
	@docker-compose run --rm alpine shards build  $(COMPILE_FLAGS) $(LINK_FLAGS) $(BUILD_TARGET) $(O)

.PHONY: crawler-dev
crawler-dev: BUILD_TARGET=crawler-dev
crawler: COMPILE_FLAGS=--static
crawler-dev: build

.PHONY: crawler
crawler: BUILD_TARGET=crawler
crawler: COMPILE_FLAGS=--release --static
crawler: build

.PHONY: console
console:
	@docker-compose run --rm alpine sh

######################################################################
### testing

.PHONY: ci
ci: test crawler

.PHONY: test
test: spec

.PHONY: spec
spec:
	@docker-compose run --rm alpine crystal spec -v --fail-fast $(LINK_FLAGS)

######################################################################
### generating

GENERATOR  ?= bin/crawler-dev
JSON_FILES ?= $(wildcard json/crawler/*.json)
CONVERTERS ?= $(addsuffix .cr,$(addprefix src/crawler/converter/,$(basename $(notdir $(wildcard proto/crawler/*.proto)))))

.PHONY: gen
gen: proto converter

.PHONY: converter
converter: $(CONVERTERS)

src/crawler/converter/%.cr:proto/crawler/%.proto $(GENERATOR)
	@if ! which "$(GENERATOR)" > /dev/null ; then echo "GENERATOR not set"; exit 1; fi
	$(GENERATOR) pb schema2converter $< "Crawler::" > $@

proto/crawler/%.proto:json/crawler/%.json
	@if ! which "$(GENERATOR)" > /dev/null ; then echo "GENERATOR not set"; exit 1; fi
	$(GENERATOR) pb json2schema $< > $@

.PHONY: proto
proto: $(subst json,proto,$(JSON_FILES))
	@mkdir -p src/proto
	protoc -I proto --crystal_out src/proto proto/*.proto
	@mkdir -p src/crawler/proto
	PROTOBUF_NS=Crawler::Proto protoc -I proto -I proto/crawler --crystal_out src/crawler/proto proto/crawler/*.proto

######################################################################
### versioning

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1)
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')

.PHONY : version
version: README.md
	@if [ "$(VERSION)" = "" ]; then \
	  echo "ERROR: specify VERSION as bellow. (current: $(CURRENT_VERSION))";\
	  echo "  make version VERSION=$(GUESSED_VERSION)";\
	else \
	  sed -i -e 's/^version: .*/version: $(VERSION)/' shard.yml ;\
	  sed -i -e 's/^    version: [0-9]\+\.[0-9]\+\.[0-9]\+/    version: $(VERSION)/' $< ;\
	  echo git commit -a -m "'$(COMMIT_MESSAGE)'" ;\
	  git commit -a -m 'version: $(VERSION)' ;\
	  git tag "v$(VERSION)" ;\
	fi

.PHONY : bump
bump:
	make version VERSION=$(GUESSED_VERSION) -s
