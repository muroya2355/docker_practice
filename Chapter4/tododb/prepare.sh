#!/bin/bash -e

# Mater/Slave 間でのレプリケーション準備をし、Slave コンテナ実行時に
# 自動的にレプリケーション設定されるようにする

# Master と Slave を環境変数で制御する

if [ ! -z "${MYSQL_MASTER}"]; then
  echo "this container is master"
  return 0
fi

echo "prepare as slave"

# Slave から Master への疎通確認をする
if [ -z "${MYSQL_MASTER_HOST}"]; then
  echo "mysql_master_host is not specified" 1>&2
  return 1
fi

while :
do
  if mysql -h ${MYSQL_MASTER_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "quit" > /dev/null 2>&1 ; then
    echo "MYSQL master is ready!"
    break
  else
    echo "MYSQL master is not ready"
    break
  fi
  sleep 3
done

# Master にレプリケーション用のユーザと権限の設定
IP=`hostname -i`
IFS='.'
set -- ${IP}
SOURCE_IP="$1.$2.%.%"
mysql -h ${MYSQL_MASTER_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e \
"CREATE USER IF NOT EXISTS '${MYSQL_REPL_USER}'@'${SOURCE_IP}' IDENTIFIED BY '${MYSQL_REPL_PASSWORD}';"
mysql -h ${MYSQL_MASTER_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e \
"GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_REPL_USER}'@'${SOURCE_IP}';"

# Master の binlog のポジションを取得
MASTER_STATUS_FILE=/tmp/master-status
mysql -h ${MYSQL_MASTER_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G" \
> ${MASTER_STATUS_FILE}
BINLOG_FILE=`cat ${MASTER_STATUS_FILE} | grep File | xargs | cut -d' ' -f2`
BINLOG_POSITION=`cat ${MASTER_STATUS_FILE} | grep Position | xargs | cut -d' ' -f2`
echo "BINLOG_FILE=${BINLOG_FILE}"
echo "BINLOG_POSITION=${BINLOG_POSITION}"

# レプリケーションを開始
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \
"CHANGE MASTER TO MASTER_HOST='${MYSQL_MASTER_HOST}';\
MASTER_USER='${MYSQL_REPL_USER}';\
MASTER_PASSWORD='${MYSQL_REPL_PASSWORD}';\
MASTER_LOG_FILE='${BINLOG_FILE}';\
MASTER_LOG_POS=${BINLOG_POSITION};"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "START SLAVE;"

echo "slave started"