FROM alpine:edge AS builder
RUN apk add --no-cache crystal shards libc-dev make \
    yaml-dev libxml2-dev sqlite-dev zlib-dev openssl-dev \
    sqlite-static zlib-static openssl-libs-static
WORKDIR /build
COPY ./shard.yml ./shard.yml
RUN shards update && shards install
COPY ./ ./
RUN apk add --no-cache curl && \
    curl -Lo /etc/apk/keys/omarroth.rsa.pub https://github.com/omarroth/boringssl-alpine/releases/download/1.1.0-r0/omarroth.rsa.pub && \
    curl -Lo boringssl-dev.apk https://github.com/omarroth/boringssl-alpine/releases/download/1.1.0-r0/boringssl-dev-1.1.0-r0.apk && \
    curl -Lo lsquic.apk https://github.com/omarroth/lsquic-alpine/releases/download/2.6.3-r0/lsquic-2.6.3-r0.apk && \
    tar -xf boringssl-dev.apk && \
    tar -xf lsquic.apk
RUN mv ./usr/lib/libcrypto.a ./lib/lsquic/src/lsquic/ext/libcrypto.a && \
    mv ./usr/lib/libssl.a ./lib/lsquic/src/lsquic/ext/libssl.a && \
    mv ./usr/lib/liblsquic.a ./lib/lsquic/src/lsquic/ext/liblsquic.a

RUN crystal build ./samples/server.cr \
    --static --warnings all --error-on-warnings \
# TODO: Remove next line, see https://github.com/crystal-lang/crystal/issues/7946
    -Dmusl \
    --link-flags "-lxml2 -llzma"

FROM alpine:latest
RUN addgroup -g 1000 -S httpproxy && \
    adduser -u 1000 -S httpproxy -G httpproxy
COPY --from=builder /build/server /http_proxy
USER httpproxy
CMD [ "/http_proxy" ]