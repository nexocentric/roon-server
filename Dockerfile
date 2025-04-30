##################
## base stage
##################
FROM ubuntu:24.04 AS base

USER root

# Preconfigure debconf for non-interactive installation - otherwise complains about terminal
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
ARG DEBIAN_FRONTEND=noninteractive
ARG DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# configure apt
RUN apt update -q
RUN apt install --no-install-recommends -y -q apt-utils 2>&1 \
	| grep -v "debconf: delaying package configuration"
RUN apt install --no-install-recommends -y -q ca-certificates

# install prerequisites
# Roon prerequisites:
#  - Roon requirements: ffmpeg libasound2
#  - Roon access samba mounts: cifs-utils
#  - Roon play to local audio device: alsa
#  - Query USB devices inside Docker container: usbutils udev
RUN apt install --no-install-recommends -y -q ffmpeg
RUN apt install --no-install-recommends -y -q libasound2-dev
RUN apt install --no-install-recommends -y -q cifs-utils
RUN apt install --no-install-recommends -y -q alsa
RUN apt install --no-install-recommends -y -q usbutils
RUN apt install --no-install-recommends -y -q udev
# app prerequisites
#  - Docker healthcheck: curl
#  - App entrypoint downloads Roon: wget bzip2
#  - set timezone: tzdata
RUN apt install --no-install-recommends -y -q curl
RUN apt install --no-install-recommends -y -q wget
RUN apt install --no-install-recommends -y -q bzip2
RUN apt install --no-install-recommends -y -q tzdata

# apt cleanup
RUN apt autoremove -y -q
RUN apt clean -y -q
RUN rm -rf /var/lib/apt/lists/*

####################
## application stage
####################
FROM scratch
COPY --from=base / /
LABEL maintainer="elgeeko1"
LABEL source="https://github.com/elgeeko1/roon-server-docker"

# Roon documented ports
#  - multicast (discovery?)
EXPOSE 9003/udp
#  - Roon Display
EXPOSE 9100/tcp
#  - RAAT
EXPOSE 9100-9200/tcp
#  - Roon events from cloud to core (websocket?)
EXPOSE 9200/tcp
# Chromecast devices
EXPOSE 30000-30010/tcp

# See https://github.com/elgeeko1/roon-server-docker/issues/5
# https://community.roonlabs.com/t/what-are-the-new-ports-that-roon-server-needs-open-in-the-firewall/186023/16
EXPOSE 9330-9339/tcp

# ports experimentally determined; or, documented
# somewhere and source forgotten; or, commented
# in a forum without explanation. I swear I know
# what these ports do but I've run out of space
# in the margin to write the solution. Either way
# there are no other services running in the
# container that should bind to these ports,
# so exposing them shouldn't pose a security risk.
EXPOSE 9001-9002/tcp
EXPOSE 49863/tcp
EXPOSE 52667/tcp
EXPOSE 52709/tcp
EXPOSE 63098-63100/tcp

USER root

# change to match your local zone.
# matching container to host timezones synchronizes
# last.fm posts, filesystem write times, and user
# expectations for times shown in the Roon client.
ARG TZ="America/Los_Angeles"
ENV TZ=${TZ}
RUN echo "${TZ}" > /etc/timezone \
	&& ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
	&& dpkg-reconfigure -f noninteractive tzdata

# copy application files
COPY ./run.sh /run.sh
RUN  chmod +x /run.sh
COPY README.md /README.md

# configure filesystem
## map a volume to this location to retain Roon Server data
RUN mkdir -p /opt/RoonServer
## map a volume to this location to retain Roon Server cache
RUN mkdir -p /var/roon

# create /music directory (users may override with a volume)
RUN mkdir -p /music

# entrypoint
# set environment variables consumed by RoonServer
# startup script
ARG DISPLAY=localhost:0.0
ENV DISPLAY=${DISPLAY}
ENV ROON_DATAROOT=/var/roon
ENV ROON_ID_DIR=/var/roon

ENTRYPOINT ["/run.sh"]
HEALTHCHECK --interval=1m --timeout=1s \
	CMD curl -f http://localhost:9330/display
