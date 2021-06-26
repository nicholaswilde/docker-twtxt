FROM golang:1.16.5-alpine3.14 as dl
ARG VERSION
ARG CHECKSUM
ARG FILENAME="${VERSION}.tar.gz"
WORKDIR /tmp
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    wget=1.21.1-r1 \
    build-base=0.5-r2 \
    git=2.32.0-r0 \
    make=4.3-r0 \
    ffmpeg-dev=4.4-r1 && \
  echo "**** download twtxt ****" && \
  mkdir /app && \
  wget -q "https://github.com/prologic/twtxt/archive/refs/tags/${FILENAME}" && \
  echo "${CHECKSUM}  ${FILENAME}" | sha256sum -c && \
  tar -xvf "${FILENAME}" -C /app --strip-components 1
WORKDIR /app
RUN \
  echo "**** build twtxt ****" && \
  make deps && \
  go mod download && \
  make server \
    VERSION="${VERSION}" \
    COMMIT="HEAD"

FROM ghcr.io/linuxserver/baseimage-alpine:3.14
ARG BUILD_DATE
ARG VERSION
# hadolint ignore=DL3048
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nicholaswilde"
ENV GODEBUG=netdns=cgo
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    ffmpeg=4.4-r1 \
    ca-certificates=20191127-r5 && \
  mkdir /data && \
  mkdir -p /config/feeds && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*
COPY --from=dl /app/twtd /app/twtd
COPY root/ /
EXPOSE 8000
VOLUME \
  /data \
  /config
