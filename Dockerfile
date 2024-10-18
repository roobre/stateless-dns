FROM debian:12@sha256:e11072c1614c08bf88b543fcfe09d75a0426d90896408e926454e88078274fcb as builder
ARG PDNS_VERSION=4.7.3

WORKDIR /build
RUN apt update && \
    apt install -y curl bzip2 g++ python3-venv libtool make pkg-config \
    libboost-all-dev libssl-dev libluajit-5.1-dev libcurl4-openssl-dev libsqlite3-dev
RUN curl -sL https://downloads.powerdns.com/releases/pdns-$PDNS_VERSION.tar.bz2 | tar -jx
WORKDIR /build/pdns-$PDNS_VERSION
RUN ./configure --with-modules='bind gsqlite3' && \
    make -j $(nproc) && \
    make install
RUN mkdir -p /usr/local/share/pdns && cp modules/gsqlite3backend/schema.sqlite3.sql /usr/local/share/pdns/schema.sqlite3.sql

FROM debian:12-slim@sha256:36e591f228bb9b99348f584e83f16e012c33ba5cad44ef5981a1d7c0a93eca22

RUN apt update && apt install -y curl sqlite3 luajit libboost-dev libboost-program-options-dev && apt clean

# REMINDER: .dockerignore defaults to exclude everything. Add exceptions to be copied there.
ADD entrypoint.sh /entrypoint/script

COPY --from=builder /usr/local /usr/local

EXPOSE 53 53/udp

ENTRYPOINT [ "/bin/bash", "/entrypoint/script" ]
CMD [ "/usr/local/sbin/pdns_server" ]
