# inferzero's server container. Build with the exact upstream release tag:
# docker build --build-arg INFERZERO_RELEASE=2026.11.21.18 -t ghcr.io/catduckgnaf/inferzero:2026.11.21.18 .
FROM ubuntu:24.04
ARG INFERZERO_RELEASE
ARG INFERZERO_ASSET_SHA256
ARG DEBIAN_FRONTEND=noninteractive
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    fp="$(curl -fsSL https://api.launchpad.net/1.0/~kobuk-team/+archive/ubuntu/intel-graphics | sed -n 's/.*"signing_key_fingerprint": *"\([0-9A-F]*\)".*/\1/p')"; \
    test -n "$fp"; \
    install -d /etc/apt/keyrings; \
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${fp}" -o /etc/apt/keyrings/kobuk-team.asc; \
    . /etc/os-release; \
    printf 'Types: deb\nURIs: https://ppa.launchpadcontent.net/kobuk-team/intel-graphics/ubuntu\nSuites: %s\nComponents: main\nSigned-By: /etc/apt/keyrings/kobuk-team.asc\n' "$VERSION_CODENAME" > /etc/apt/sources.list.d/kobuk-team.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends intel-opencl-icd libze-intel-gpu1 libze1 ocl-icd-libopencl1 libgomp1 poppler-utils; \
    rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    test -n "$INFERZERO_RELEASE"; \
    test -n "$INFERZERO_ASSET_SHA256"; \
    api="https://api.github.com/repos/rizagp/inferzero/releases/tags/${INFERZERO_RELEASE}"; \
    asset="$(curl -fsSL "$api" | sed -n 's/.*"browser_download_url": *"\([^"]*linux-x64\.tar\.gz\)".*/\1/p' | head -n 1)"; \
    test -n "$asset"; \
    curl -fsSL "$asset" -o /tmp/inferzero.tar.gz; \
    echo "${INFERZERO_ASSET_SHA256}  /tmp/inferzero.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/inferzero.tar.gz -C /opt; \
    rm /tmp/inferzero.tar.gz; \
    ln -s /opt/inferzero-*-linux-x64 /opt/inferzero
WORKDIR /opt/inferzero
COPY entrypoint.sh /usr/local/bin/inferzero-entrypoint
RUN chmod 0755 /usr/local/bin/inferzero-entrypoint
EXPOSE 8090
ENTRYPOINT ["/usr/local/bin/inferzero-entrypoint"]
