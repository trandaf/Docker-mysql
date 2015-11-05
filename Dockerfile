FROM debian:jessie

RUN apt-get update
RUN apt-get install -y mysql-server


RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN mkdir -p /var/log/mysql && chown -R mysql.mysql /var/log/mysql

ADD entrypoint.sh /usr/local/bin/
RUN chown mysql.mysql /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "--relay-log=/var/log/mysql/mysql-relay-bin.log"]
CMD [""]

EXPOSE 3306
VOLUME /var/log
VOLUME /var/lib/mysql
