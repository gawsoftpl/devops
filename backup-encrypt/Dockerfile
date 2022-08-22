FROM alpine as downloader

RUN wget -O /tmp/age-v1.0.0-linux-amd64.tar.gz  https://github.com/FiloSottile/age/releases/download/v1.0.0/age-v1.0.0-linux-amd64.tar.gz \
    && tar -xvf /tmp/age-v1.0.0-linux-amd64.tar.gz 

FROM amazon/aws-cli:latest

COPY --from=downloader /age/age /usr/bin
