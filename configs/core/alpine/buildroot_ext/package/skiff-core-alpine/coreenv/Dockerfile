# multi-architecture image
FROM alpine:edge as builder

RUN apk upgrade --no-cache
RUN apk add --no-cache \
    ca-certificates \
    openrc \
    sudo \
    bash
RUN rm /var/cache/apk/* || true

FROM scratch

# flatten the image to one layer
COPY --from=builder / /

ENTRYPOINT ["/sbin/init"]
CMD []
