# syntax=docker/dockerfile:1
#
# Packages VectorChord as a CloudNativePG extension image volume.
#
# The resulting image is FROM scratch and only carries the extension's files in
# the layout CloudNativePG expects:
#   /lib/vchord.so                  (dynamic_library_path, default /lib)
#   /share/extension/vchord*        (extension_control_path, default /share)
#
# It is never executed; the .so is loaded by the PostgreSQL container, which
# provides glibc/libgcc. vchord also requires the `vector` extension (pgvector),
# mounted as a separate image volume.

ARG PG_MAJOR=18
ARG VCHORD_VERSION=1.1.1

FROM debian:trixie-slim AS builder
ARG PG_MAJOR
ARG VCHORD_VERSION
# Provided automatically by buildx, one value per --platform (amd64, arm64).
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL -o /tmp/vchord.deb \
      "https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-${PG_MAJOR}-vchord_${VCHORD_VERSION}-1_${TARGETARCH}.deb"; \
    dpkg-deb -x /tmp/vchord.deb /extract; \
    mkdir -p /out/lib /out/share; \
    cp -a "/extract/usr/lib/postgresql/${PG_MAJOR}/lib/." /out/lib/; \
    cp -a "/extract/usr/share/postgresql/${PG_MAJOR}/." /out/share/; \
    test -f /out/lib/vchord.so; \
    test -f /out/share/extension/vchord.control

FROM scratch
COPY --from=builder /out/ /
