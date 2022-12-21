ARG MYSQL_TAG=latest

FROM mysql:${MYSQL_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

ARG TIMEZONE=UTC
ENV TIMEZONE ${TIMEZONE}
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone && chown -R mysql:root /var/lib/mysql/

COPY ./my.cnf /etc/mysql/conf.d/my.cnf

RUN chmod 0444 /etc/mysql/conf.d/my.cnf

CMD ["mysqld"]

EXPOSE 3306
