FROM photon:latest

LABEL org.opencontainers.image.authors="mackid1993"

ENV FFMPEG_PKG=ffmpeg-git-amd64-static.tar.xz

WORKDIR "/app"

RUN tdnf update -y \
        && tdnf -y install sudo bzip2 cifs-utils alsa-utils wget icu xz

RUN curl -O https://johnvansickle.com/ffmpeg/builds/${FFMPEG_PKG}

RUN tar -xf ${FFMPEG_PKG} && rm ${FFMPEG_PKG} \
        && mv ffmpeg-git-* /var/lib/ffmpeg

WORKDIR "/var/lib/ffmpeg"

RUN ln -s "${PWD}/ffmpeg" /usr/local/bin/ \
        && ln -s "${PWD}/ffprobe" /usr/local/bin/

ENV ROON_SERVER_PKG=RoonServer_linuxx64.tar.bz2
ENV ROON_SERVER_URL=https://download.roonlabs.net/builds/${ROON_SERVER_PKG}
ENV ROON_DATAROOT=/data
ENV ROON_ID_DIR=/data

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

VOLUME [ "/app", "/data", "/music", "/backup" ]

ADD ./run.sh /app/run.sh

RUN chmod 755 /app/run.sh

ENTRYPOINT ["/app/run.sh"]
