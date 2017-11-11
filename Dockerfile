FROM alpine:latest
MAINTAINER Evgeniy Shumilov <evgeniy.shumilov@gmail.com>

RUN apk add --update mysql mysql-client sudo && rm -f /var/cache/apk/*
COPY init.sh /init.sh

EXPOSE 3306
VOLUME /var/lib/mysql

ENTRYPOINT /init.sh
