FROM alpine as downloader

WORKDIR /tmp

RUN wget -O age-v1.0.0-linux-amd64.tar.gz  https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz \
    && tar -xvf /tmp/age-v1.0.0-linux-amd64.tar.gz \
    && chmod +x /tmp/age/age

RUN wget -O /tmp/restic.bz2 https://github.com/restic/restic/releases/download/v0.14.0/restic_0.14.0_linux_amd64.bz2 \
  && bzip2 -d /tmp/restic.bz2 \
  && chmod +x /tmp/restic 

FROM alpine

RUN apk update \
  && apk add coreutils \
  && rm -rf /var/cache/apk/*

RUN addgroup -S backup && adduser -u 2000 -S backup -G backup

COPY --from=downloader /tmp/age/age /usr/bin
COPY --from=downloader /tmp/restic /usr/bin

COPY backup_encrypt_s3 /usr/bin/backup_encrypt_s3
COPY retention /usr/bin/retention
COPY istio_stop /usr/bin/istio_stop

USER backup