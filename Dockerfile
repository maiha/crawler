FROM crystallang/crystal:1.1.1-alpine

RUN apk update && apk add --no-cache \
    yaml-static \
    curl-static \
    libidn2-static \
    nghttp2-static \
    brotli-static \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apk/*

CMD ["crystal", "--version"]
