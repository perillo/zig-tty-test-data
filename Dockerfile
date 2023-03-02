# syntax=docker/dockerfile:1.4
FROM alpine:3
ARG uid

RUN mkdir /var/tmp/zig
WORKDIR /var/tmp/zig

# Install dependencies.
RUN apk add --no-cache git python3

# Install Zig.
COPY download-zig.py .
RUN <<EOT
  set -e

  mkdir spool
  zig_tarball=$(./download-zig.py)

  mkdir /usr/local/lib/zig
  printf "installing %s\n" $zig_tarball
  tar -axvf "$zig_tarball" -C /usr/local/lib/zig --strip-components=1
  ln -s /usr/local/lib/zig/zig /usr/local/bin
EOT

# Install zstring-decode.
RUN <<EOT
  set -e

  git clone --depth 1 https://github.com/perillo/zstring-decode.git
  cd zstring-decode
  zig build -p /usr/local
EOT

# Cleanup.
WORKDIR /
RUN rm -rf /var/tmp/zig

# Drop privileges.
RUN adduser -D -H -u ${uid} zig
USER zig
WORKDIR /home/zig

COPY --chown=zig gen-test-data.sh .

ENTRYPOINT [ "./gen-test-data.sh" ]
