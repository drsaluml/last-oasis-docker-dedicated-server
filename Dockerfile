FROM ubuntu:24.04

ENV IN_DOCKER=1

ENV USER=steam
ENV UID=1000
ENV GID=1001

# Install dependencies first — Ubuntu 24.04's minimal base does not
# include the `adduser` package, so addgroup/adduser would fail with
# "command not found" otherwise.
RUN apt-get update -y \
 && apt-get install -y --no-install-recommends \
      adduser \
      ca-certificates \
      curl \
      lib32gcc-s1 \
      lib32stdc++6 \
      python3-minimal \
 && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 ships with a default `ubuntu` user/group at UID/GID 1000.
# Remove it so we can claim UID 1000 for `steam` (matches existing
# named volumes built on earlier base images).
RUN userdel --remove ubuntu 2>/dev/null || true \
 && groupdel ubuntu 2>/dev/null || true

RUN addgroup \
    --system \
    --gid "$GID" \
    "$USER"

RUN adduser \
    --disabled-password \
    --ingroup "$USER" \
    --system \
    --uid "$UID" \
    --home /home/"$USER" \
    --shell /bin/bash \
    "$USER"

RUN mkdir -p /mnt/steam
RUN chown -R steam:steam /mnt/steam/
VOLUME ["/mnt/steam/"]

# Point HOME at the volume mount so steamcmd's defaults — $HOME/.steam
# and $HOME/Steam — land directly inside the persistent volume. No
# symlinks needed; steamcmd creates the subdirectories itself.
#
# Image-side files (scripts, steamcmd binary) still live in
# /home/steam (WORKDIR below); only the per-install state is in HOME.
ENV HOME=/mnt/steam

USER steam
WORKDIR /home/steam

RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Run once non-interative to download steam files
RUN ./steamcmd.sh --help

COPY --chown=steam ./ ./

HEALTHCHECK --interval=60s --timeout=10s --start-period=180s --retries=3 \
  CMD python3 /home/steam/src/healthcheck || exit 1

ENTRYPOINT ["/home/steam/last-oasis"]
CMD ["help"]
