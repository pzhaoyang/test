FROM --platform=linux/armv7 ubuntu:18.04

ARG S6_OVERLAY_VERSION=v1.22.1.0
ARG ARCH=armhf
ARG PLEX_BUILD=linux-armhf
ARG PLEX_DISTRO=debian
##[
ARG S6_OVERLAY_PATH="https://github.com/just-containers/s6-overlay/releases/download"
ARG PLEX_DOWNLOAD="https://downloads.plex.tv/plex-media-server-new" 
ARG PLEX_RELEASE=1.19.1.2645-ccb6eb67e
##]
ARG DEBIAN_FRONTEND="noninteractive"
ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

ENTRYPOINT ["/init"]

# Update sources to China
#COPY sources.list /etc/apt/sources.list

# Update and get dependencies
RUN apt-get update
RUN apt-get install -y \
 apt-utils \
 curl \
 tzdata \
 axel \
 xmlstarlet \
 uuid-runtime \
 jq \
 unrar \
 --fix-missing --fix-broken

# Fetch and extract S6 overlay
#RUN axel -n 20 -S5 ${S6_OVERLAY_PATH}/${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.gz -o /tmp/s6-overlay-${ARCH}.tar.gz

COPY s6-overlay-${ARCH}.tar.gz /tmp/s6-overlay-${ARCH}.tar.gz
RUN tar xzf /tmp/s6-overlay-${ARCH}.tar.gz -C /

# Add user
RUN useradd -U -d /config -s /bin/false plex && \
    usermod -G users plex

# Setup directories
RUN mkdir -p \
      /config \
      /transcode \
      /data

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ENV CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

ARG TAG=beta
ARG URL=

#COPY root/ /
COPY root/plex-common.sh /plex-common.sh
COPY root/healthcheck.sh /healthcheck.sh
COPY root/etc/cont-init.d/40-plex-first-run /etc/cont-init.d/40-plex-first-run
COPY root/etc/cont-init.d/45-plex-hw-transcode-and-connected-tuner /etc/cont-init.d/45-plex-hw-transcode-and-connected-tuner
COPY root/etc/services.d/plex/run /etc/services.d/plex/run

# Save version and install
#RUN /installBinary.sh
#RUN axel -n5 -S5 "${PLEX_DOWNLOAD}/${PLEX_RELEASE}/debian/plexmediaserver_${PLEX_RELEASE}_${ARCH}.deb" -o /tmp/plexmediaserver.deb
FROM multiarch/ubuntu-debootstrap:armhf-bionic AS install

COPY plexmediaserver_${PLEX_RELEASE}_${ARCH}.deb /tmp/plexmediaserver.deb
RUN  uname -a
#RUN ls -l plexmediaserver_1.19.1.2645-ccb6eb67e_armhf.deb /tmp/plexmediaserver.deb
RUN dpkg -i --force-confold /tmp/plexmediaserver.deb

# Cleanup
RUN apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* \
    rm -rf /etc/default/plexmediaserver


HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1
