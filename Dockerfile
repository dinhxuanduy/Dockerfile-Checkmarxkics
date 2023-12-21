FROM alpine as downloader
RUN wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-minirootfs-3.19.0-x86_64.tar.gz

FROM scratch
COPY --from=downloader /alpine-minirootfs-3.19.0-x86_64.tar.gz /
ADD alpine-minirootfs-3.19.0-x86_64.tar.gz /
RUN apk update && apk add postgresql
RUN mkdir /run/postgresql && chown postgres:postgres /run/postgresql/
USER postgres
RUN mkdir /var/lib/postgresql/data && chmod 0700 /var/lib/postgresql/data &&\
    initdb -D /var/lib/postgresql/data &&\
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf &&\
    echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf &&\
#    sed -i '/unix_socket_directories =/d' /var/lib/postgresql/data/postgresql.conf &&\
#    echo "unix_socket_directories = '/tmp'" >> /var/lib/postgresql/data/postgresql.conf &&\
    pg_ctl start -D /var/lib/postgresql/data &&\
    psql -h localhost -p 5432 -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'main'" | grep -q 1 || psql -U postgres -c "CREATE DATABASE main" &&\
    psql -h localhost -p 5432 -U postgres -c "ALTER USER postgres WITH ENCRYPTED PASSWORD 'mysecurepassword';" &&\
    pg_ctl stop -D /var/lib/postgresql/data
# Expose the PostgreSQL port
EXPOSE 5432
CMD ["postgres", "-D", "/var/lib/postgresql/data"]
