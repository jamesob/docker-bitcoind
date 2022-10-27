FROM buildpack-deps:buster-curl as builder
LABEL MAINTAINER="James O'Beirne <wild-dockerbitcoind@au92.org>"

# These buildargs can be set during container build time with e.g.
# --build-arg VERSION=[version]

# Can be "release" or "git"
ARG SOURCE=
# If SOURCE is git, this should be blank.
ARG VERSION=

ARG GIT_REF=
ARG GIT_SHA=
ARG GIT_REPO_URL=
ARG CONFIGURE_ARGS=

LABEL "bitcoin-source"=$SOURCE
LABEL "bitcoin-version"=$VERSION
LABEL "bitcoin-configure-args"="$CONFIGURE_ARGS"
LABEL "git-ref"=${GIT_REF}
LABEL "git-sha"=${GIT_SHA}
LABEL "git-repo-url"=${GIT_REPO_URL}

ENV PYTHONUNBUFFERED=1

RUN apt-get update && \
  apt-get install -y gnupg2 curl sudo python3 && \
  rm -rf /var/lib/apt/lists/*

# Install build deps, if necessary.
RUN if [ "${SOURCE}" = "git" ] ; then apt-get update && \
  apt-get install -y \
    git build-essential libtool autotools-dev automake \
    pkg-config bsdmainutils libevent-dev libboost-dev libsqlite3-dev \
    systemtap-sdt-dev libzmq3-dev g++ && \
  rm -rf /var/lib/apt/lists/* ; fi


COPY ./bin/get-bitcoin /usr/bin/
RUN chmod +x /usr/bin/get-bitcoin && \
  mkdir /root/bitcoin && \
  get-bitcoin \
    --version "${VERSION}" \
    --git-ref "${GIT_REF}" \
    --git-sha "${GIT_SHA}" \
    --git-repo-url "${GIT_REPO_URL}" \
    --configure-args="${CONFIGURE_ARGS}" \
    --install-prefix /root/bitcoin/ \
    "${SOURCE}"


FROM debian:buster-slim

# Run bitcoin as a non-privileged user to avoid permissions issues with volume mounts,
# amount other things.
#
# These buildargs can be set during container build time with --build-arg UID=[uid]
ARG UID=1000
ARG GID=1000
ARG USERNAME=user

# Can be "release" or "git"
ARG SOURCE=
# If SOURCE is git, this should be blank.
ARG VERSION=

ARG GIT_REF=
ARG GIT_SHA=
ARG GIT_REPO_URL=
ARG CONFIGURE_ARGS=

LABEL "bitcoin-source"=$SOURCE
LABEL "bitcoin-version"=$VERSION
LABEL "bitcoin-configure-args"="$CONFIGURE_ARGS"
LABEL "git-ref"=${GIT_REF}
LABEL "git-sha"=${GIT_SHA}
LABEL "git-repo-url"=${GIT_REPO_URL}

RUN apt-get update && \
  apt-get install -y iproute2 sudo libevent-pthreads-2.1-6 libzmq5 libsqlite3-0 && \
  rm -rf /var/lib/apt/lists/*

# Install shared library requirements if we aren't using release binaries
RUN if [ "${SOURCE}" = "git" ]; then \
  apt update && apt install -y \
  libevent-2.1-6 libevent-pthreads-2.1-6 libzmq5 libsqlite3-0 && \
  rm -rf /var/lib/apt/lists/* \
  ; fi

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
