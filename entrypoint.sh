#!/bin/bash

#### VARS ####
MYSQL_ROOT_PASS="ready2gogo"
MYSQL_USER="root"
MYSQL_REP_USER="replication"
MYSQL_REP_PASS="replpass"
MYSQL_MG_USER="magento"
MYSQL_MG_PASS="ready2gogo"
MYSQL_MG_DB="magento"
MYSQL_MASTER_LOGBIN="/var/log/mysql/mysql-bin.log"
MYSQL_RELAY_LOGBIN="/var/log/mysql/mysql-relay-bin.log"

DATADIR="/var/lib/mysql"




#### MAIN ####

mkdir -p "$DATADIR"
chown -R mysql:mysql "$DATADIR"

if [[ $SERVER_ID -eq 1 ]]; then 
  echo -e "[mysqld]\nserver-id=${SERVER_ID}" > /etc/mysql/conf.d/server_id.cnf
  echo -e "[mysqld]\nlog_bin=${MYSQL_MASTER_LOGBIN}" >> /etc/mysql/my.cnf
  echo -e "[mysqld]\nbinlog_do_db=${MYSQL_MG_DB}" >> /etc/mysql/my.cnf
  echo "GRANT ALL ON *.* TO ${MYSQL_USER}@'%' IDENTIFIED BY '${MYSQL_ROOT_PASS}' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
  echo "GRANT ALL ON *.* TO ${MYSQL_REP_USER}@'%' IDENTIFIED BY '${MYSQL_REP_PASS}' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
  echo "GRANT ALL ON *.* TO ${MYSQL_MG_USER}@'%' IDENTIFIED BY '${MYSQL_MG_PASS}' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
  kill $(pidof mysqld)
  sleep 3
  
else
  echo -e "[mysqld]\nserver-id=${SERVER_ID}" > /etc/mysql/conf.d/server_id.cnf
  echo "GRANT ALL ON *.* TO ${MYSQL_USER}@'%' IDENTIFIED BY '${MYSQL_ROOT_PASS}' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
  echo "GRANT ALL ON *.* TO ${MYSQL_MG_USER}@'%' IDENTIFIED BY '${MYSQL_MG_PASS}' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
  mysqldump -h master -u ${MYSQL_USER} -p ${MYSQL_ROOT_PASS} ${MYSQL_MG_DB} > /root/${MYSQL_MG_DB}.sql
  mysql -u root -p${MYSQL_ROOT_PASS} ${MYSQL_MG_DB} < /root/${MYSQL_MG_DB}.sql
  echo -e "[mysqld]\nserver-id=${SERVER_ID}" > /etc/mysql/conf.d/server_id.cnf
  echo -e "[mysqld]\nlog_bin=${MYSQL_MASTER_LOGBIN}" >> /etc/mysql/my.cnf
  echo -e "[mysqld]\nlog_bin=${MYSQL_RELAY_LOGBIN}" >> /etc/mysql/my.cnf
  echo -e "[mysqld]\nbinlog_do_db=${MYSQL_MG_DB}" >> /etc/mysql/my.cnf
  kill $(pidof mysqld)
  sleep 3

  echo "CHANGE MASTER TO MASTER_HOST='$master',MASTER_USER='$MYSQL_REP_USER', MASTER_PASSWORD='$MYSQL_REP_PASS', MASTER_LOG_FILE='$MASTER_LOG_FILE', MASTER_LOG_POS=$MASTER_LOG_POSITION;" | mysql

fi


if [[ "${@}" =~ ^-- ]]; then
  args="${@}"
fi

exec /usr/bin/mysqld_safe --max-allowed-packet=1024M --log-bin=/var/log/mysql/mysql-bin.log --relay-log=/var/log/mysql/mysql-relay-bin.log $args
