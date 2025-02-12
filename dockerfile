FROM mysql:8.0

ENV MSSQL_PID Express
ENV MYSQL_ROOT_PASSWORD coderunnerhackerrank

USER root
RUN groupadd -g 2000 coderunner \
    && useradd -u 1001 -g 2000 coderunner

RUN chown -R 1001:2000 /var/lib/mysql \
    && chown -R 1001:2000 /var/run/mysqld

COPY my.cnf /etc/mysql/my.cnf

USER coderunner