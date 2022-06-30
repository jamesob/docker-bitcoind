FROM buildpack-deps:buster-curl as builder
LABEL MAINTAINER="James O'Beirne <wild-dockerbitcoind@au92.org>"

# This buildarg can be set during container build time with --build-arg VERSION=[version]
ARG VERSION=0.20.1

RUN apt-get update && \
  apt-get install -y gnupg2 curl && \
  rm -rf /var/lib/apt/lists/*

COPY ./bin/get-bitcoin.sh /usr/bin/
RUN chmod +x /usr/bin/get-bitcoin.sh && \
  mkdir /root/bitcoin && \
  get-bitcoin.sh $VERSION /root/bitcoin/


FROM debian:buster-slim

# Run bitcoin as a non-privileged user to avoid permissions issues with volume mounts,
# amount other things.
#
# These buildargs can be set during container build time with --build-arg UID=[uid]
ARG UID=1000
ARG GID=1000
ARG USERNAME=user

RUN apt-get update && \
  apt-get install -y iproute2 sudo && \
  rm -rf /var/lib/apt/lists/*

# Workaround to address https://github.com/jamesob/docker-bitcoind/pull/16 while
# still not running as root user.
COPY ./bin/append-to-hosts.sh /usr/bin/append-to-hosts
RUN chmod +x /usr/bin/append-to-hosts

# Allow the new user write access to /etc/hosts for the fix in `entrypoint.sh`.
RUN groupadd -g $GID -o $USERNAME && \
  useradd -m -u $UID -g $GID -o -d /home/$USERNAME -s /bin/bash $USERNAME && \
  echo "$USERNAME    ALL=(ALL:ALL) NOPASSWD: /usr/bin/append-to-hosts" | tee -a /etc/sudoers

COPY --from=builder /root/bitcoin/ /usr/local/
COPY ./entrypoint.sh /usr/local/entrypoint.sh
RUN chmod a+rx /usr/local/entrypoint.sh && \
  mkdir -p /bitcoin/data && \
  chown -R $USERNAME:$GID /bitcoin

USER $USERNAME

EXPOSE 8332 8333 18332 18333 28332 28333

ENTRYPOINT ["/usr/local/entrypoint.sh"]
