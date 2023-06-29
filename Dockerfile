FROM alpine:3.18
MAINTAINER Evgeniy Shumilov <evgeniy.shumilov@gmail.com>

RUN apk add --update mysql mysql-client sudo && rm -f /var/cache/apk/*
COPY init.sh /usr/local/bin/init.sh
COPY check.sh /usr/local/bin/check.sh
VOLUME /var/lib/mysql

#RUN /usr/local/bin/init.sh

EXPOSE 3306
HEALTHCHECK --interval=30s --timeout=3s CMD /usr/local/bin/check.sh

ENTRYPOINT /usr/local/bin/init.sh
#ENTRYPOINT sudo -u mysql mysqld_safe 
