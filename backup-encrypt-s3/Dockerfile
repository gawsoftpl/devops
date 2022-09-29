FROM alpine as downloader

WORKDIR /tmp

RUN wget -O age-v1.0.0-linux-amd64.tar.gz  https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz \
    && tar -xvf /tmp/age-v1.0.0-linux-amd64.tar.gz \
    && chmod +x /tmp/age/age

RUN wget -O s5cmd.tar.gz https://github.com/peak/s5cmd/releases/download/v2.0.0/s5cmd_2.0.0_Linux-64bit.tar.gz \
  && tar -xvf /tmp/s5cmd.tar.gz \
  && chmod +x /tmp/s5cmd

RUN wget -O curlie.tar.gz https://github.com/rs/curlie/releases/download/v1.6.9/curlie_1.6.9_linux_amd64.tar.gz \
  && tar -xvf curlie.tar.gz \
  && chmod +x curlie

FROM alpine

RUN addgroup -S backup && adduser -u 2000 -S backup -G backup

COPY --from=downloader /tmp/age/age /usr/bin
COPY --from=downloader /tmp/s5cmd /usr/bin
COPY --from=downloader /tmp/curlie /usr/bin

COPY backup_encrypt_s3 /usr/bin/backup_encrypt_s3
COPY retention /usr/bin/retention
COPY istio_stop /usr/bin/istio_stop

USER backup