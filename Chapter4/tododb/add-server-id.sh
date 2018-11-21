#!/bin/bash -e

# server-id を mysqld.cnf の末尾に記述
# server-id : サーバー間で一意に設定される値
#             コンテナのIPアドレスの第3・第4オクテットを利用し採番

OCTETS=(`hostname -i | tr -s '.'' '`)

MYSQL_SERVER_ID=`expr ${OCTETS[2]}\*256 + ${OCTETS[3]}`
echo "server-id=${MYSQL_SERVER_ID}">>/etc/mysql/mysql.conf.d/mysqld.cnf