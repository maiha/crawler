FROM crystallang/crystal:0.36.1-3.12-alpine

#RUN echo "@edge http://mirror.xtom.com.hk/alpine/edge/main" >> /etc/apk/repositories

RUN apk update && apk add --no-cache \
    yaml-static \
    curl-static \
    libidn2-static \
    nghttp2-static \
    && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apk/*

CMD ["crystal", "--version"]
