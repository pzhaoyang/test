FROM ubuntu@sha256:3b029ac9aa8eb5dffd43bb7326891cf64f9c228b3960cec55a56605d2ae2ad42

COPY qemu-arm-static /usr/bin
COPY s6-overlay-${ARCH}.tar.gz /tmp/s6-overlay-${ARCH}.tar.gz
COPY root/plex-common.sh /plex-common.sh
COPY root/healthcheck.sh /healthcheck.sh
COPY root/etc/cont-init.d/40-plex-first-run /etc/cont-init.d/40-plex-first-run
COPY root/etc/cont-init.d/45-plex-hw-transcode-and-connected-tuner /etc/cont-init.d/45-plex-hw-transcode-and-connected-tuner
COPY root/etc/services.d/plex/run /etc/services.d/plex/run
COPY plexmediaserver_${PLEX_RELEASE}_${ARCH}.deb /tmp/plexmediaserver.deb

ARG ARCH=armhf
ARG S6_OVERLAY_VERSION=v1.22.1.0
ARG S6_OVERLAY_PATH="https://github.com/just-containers/s6-overlay/releases/download"
ARG PLEX_DOWNLOAD="https://downloads.plex.tv/plex-media-server-new" 
ARG PLEX_RELEASE=1.19.1.2645-ccb6eb67e
ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

ENTRYPOINT ["/init"]

# Update sources to China
COPY sources.list /etc/apt/sources.list

# Update and get dependencies
RUN apt-get update && \
 apt-get install -y \
 apt-utils \
 curl \
 tzdata \
 axel \
 xmlstarlet \
 uuid-runtime \
 jq \
 unrar && \
 tar xzf /tmp/s6-overlay-${ARCH}.tar.gz -C / && \
 useradd -U -d /config -s /bin/false plex && \
 usermod -G users plex && \
 mkdir -p \
  /config \
  /transcode \
  /data && \
 dpkg -i --force-confold /tmp/plexmediaserver.deb && \
 apt-get -y autoremove && \
 apt-get -y clean && \
 rm -rf /var/lib/apt/lists/* && \
 rm -rf /tmp/* && \
 rm -rf /var/tmp/* \
 rm -rf /etc/default/plexmediaserver

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ENV CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1