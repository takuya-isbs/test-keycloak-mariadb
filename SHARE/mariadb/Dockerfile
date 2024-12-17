FROM mariadb:10.6.20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
  apt-utils \
  curl

RUN curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | bash
RUN apt -y install sysbench
COPY ./scripts/run-sysbench.sh /usr/local/bin/run-sysbench
RUN chmod +x /usr/local/bin/run-sysbench

COPY ./conf.d/galera.cnf.tmpl /galera.cnf.tmpl

COPY ./docker-entrypoint-override.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint-override.sh"]
CMD ["docker-entrypoint.sh", "mariadbd"]
