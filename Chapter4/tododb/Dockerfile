FROM mysql:5.7

# パッケージアップデートと wget インストール
RUN apt-get update
RUN apt-get install -y wget

# entrykit のインストール
RUN wget https://github.com/progrium/entrykit/releases/download/v0.4.0/entrykit_0.4.0_linux_x86_64.tgz
RUN tar -xvzf entrykit_0.4.0_linux_x86_64.tgz
RUN rm entrykit_0.4.0_linux_x86_64.tgz
RUN mv entrykit /usr/local/bin/
RUN entrykit --symlink

# スクリプトと各種設定ファイルのコピー
COPY ./add-server-id.sh /usr/local/bin
COPY ./etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/
COPY ./etc/mysql/conf.d/mysql.cnf /etc/mysql/conf.d/
COPY ./prepare.sh /docker-entrypoint-initdb.d
COPY ./init-data.sh /usr/local/bin/
COPY ./sql /sql

# スクリプトと mysqld の実行
ENTRYPOINT [ \
  "prehook", \
    "add-server-id.sh", \
    "--", \
  "docker-entrypoint.sh" \
]

CMD ["mysqld"]

