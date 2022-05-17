# multi-architecture image
ARG DISTRO
FROM ${DISTRO:-alpine:edge} as stage1

RUN apk upgrade --no-cache
RUN apk add --no-cache \
    ca-certificates \
    openrc \
    sudo \
    bash
RUN rm /var/cache/apk/* || true


# flatten the image to one layer
# RUN rm /var/cache/apk/* || true
# FROM scratch
# COPY --from=stage1 / /

ENTRYPOINT ["/sbin/init"]
CMD []
