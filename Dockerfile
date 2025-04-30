FROM photon:latest

LABEL org.opencontainers.image.authors="david@indisko.com"

ENV FFMPEG_PKG=ffmpeg-git-amd64-static.tar.xz

WORKDIR "/root"

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

VOLUME [ "/app", "/data", "/music", "/backup" ]

WORKDIR "/root"

ADD run.sh /root

RUN chmod +x /root/run.sh

EXPOSE 9330-9339/TCP 30000-30009/TCP 9003/UDP 32768-65535/UDP

ENTRYPOINT ["/root/run.sh"]