FROM quay.io/fedora/fedora:latest as build

RUN dnf --use-host-config --installroot=/staging -y install glibc && \
    dnf --use-host-config --installroot=/staging -y clean all

WORKDIR /workdir

RUN for url in \
        "https://downloads.getmonero.org/cli/linux64" \
        "https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc" \
        "https://www.getmonero.org/downloads/hashes.txt"; do \
        curl -A "Mozilla/5.0" -sSLfO "$url"; \
    done && \
    gpg --keyid-format long --with-fingerprint binaryfate.asc && \
    gpg --import binaryfate.asc && \
    gpg --verify hashes.txt && \
    checksum="$(sha256sum linux64 | awk '{print $1}')" && \
    grep -q "$checksum" hashes.txt && \
    mkdir -p /staging/app && \
    tar -C /staging/app -xjvf linux64 --strip-components=1

FROM scratch

COPY --from=build /staging /

ENTRYPOINT ["/app/monerod"]
