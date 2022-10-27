
# docker-bitcoind

[![Docker Stars](https://img.shields.io/docker/stars/jamesob/bitcoind.svg)](https://hub.docker.com/r/jamesob/bitcoind/)
[![Docker Pulls](https://img.shields.io/docker/pulls/jamesob/bitcoind.svg)](https://hub.docker.com/r/jamesob/bitcoind/)

A Docker configuration with sane defaults for running a fully-validating
Bitcoin node. Binaries are retrieved from bitcoincore.org and verified for integrity
based on [the process described here](https://bitcoincore.org/en/download/).

Optional building from arbitrary git objects is possible (and pretty convenient).

## **Warning**: don't trust the Docker registry

References on the Docker registry (https://hub.docker.com) are mutable. A malicious
actor could change any images hosted there without you realizing it.

If you use an image served by the Docker registry, ensure that you retrieve
it by its content hash, [as detailed here](https://stackoverflow.com/a/40730725).
Or just build these images yourself.

With most software this doesn't matter too much, but running an authentic copy of
Bitcoin Core is really important!

## **Warning**: don't trust Docker

Consider whether your use of Bitcoin requires Docker. When you use a container runtime,
you are using a lot of additional code written by other people, e.g. `runc`, `docker`,
potentially `docker-compose`, potentially `podman`.

Is it necessary to rely on these dependencies? More code running underneath bitcoind
is more chance for someone to meddle with the operation of your node.

## **Warning**: don't rely on Dockerfile particulars

This repo may change Dockerfile implementation. Although the container interface itself
(i.e. volume mounts, operational behavior) will remain stable, the implementation 
of how that happens is subject to change.

If your use relies on the particulars of, for example, the retrieval script
(`get-bitcoin.sh`), please pin your usage of this repo to a particular git hash.


## Tags available

- 0.13.0
- 0.13.1
- 0.13.2
- 0.14.3
- 0.15.2
- 0.16.3
- 0.17.0
- 0.17.0.1
- 0.17.1
- 0.17.2
- 0.18.0
- 0.18.1
- 0.19.0
- 0.19.1
- 0.20.0
- 0.20.1 
- 0.21.0 
- 0.21.1 
- 0.21.2 
- 22.0
- 23.0

As well as various git refs.


## Labels available

Each image is built with certain labels:

- `bitcoin_source`: "release" or "git", depending on how the binaries were built
- `bitcoin_version`: if source=release, the release version (e.g. `23.0`), if
  source=git "git:<git ref>"
- `git_ref`: if source=git, the tag or branch used to build the image
- `git_sha`: if source=git, the specific git commit hash
- `git_repo_url`: if source=git, the repo used to build

Labels can be shown by running something like
```json
% docker image inspect jamesob/bitcoind:master | jq '.[0] .Config .Labels'

{
  "bitcoin-configure-args": "--enable-reduce-exports --disable-bench --disable-gui-tests --disable-fuzz-binary --disable-ccache --disable-maintainer-mode --disable-dependency-tracking CFLAGS='-O2 -g'",
  "bitcoin-source": "git",
  "bitcoin-version": "git:master",
  "git-ref": "master",
  "git-repo-url": "https://github.com/bitcoin/bitcoin",
  "git-sha": "551c8e9526d2502f857e1ef6348c7f1380f37443"
}
```

## Quick start

Requires that [Docker be installed](https://docs.docker.com/install/) on the host machine.

### Autogenerating a config

```sh
# Create some directory where your bitcoin data will be stored.
$ mkdir /home/youruser/bitcoin_data

$ $EDITOR envfile
BTC_RPCPASSWORD=your_password

$ docker run --name bitcoind -d \
   -e 'BTC_RPCUSER=foo' \
   -e 'BTC_TXINDEX=1' \
   --env-file envfile \
   -v /home/youruser/bitcoin_data:/bitcoin/data \
   -p 127.0.0.1:8332:8332 \
   -p 8333:8333 \
   jamesob/bitcoind:0.20.1

$ docker logs -f bitcoind
[ ... ]
```

**Warning**: if you specify your RPC password without using an envfile, it may
be captured in your shell history. Use an envfile if you are going to use
`BTC_RPCPASSWORD`.

If you want the RPC port to be accessible to remote hosts, remove the `127.0.0.1` from
the `-p ...8332` line and set `BTC_RPCBIND=0.0.0.0`.

### Using your own config/datadir

If you want to use a preexisting data directory and your own config file, run

```sh
$ docker run --name jamesob/bitcoind:0.20.1 -d \
   -v /home/youruser/bitcoin_data:/bitcoin/data \
   -v /home/youruser/bitcoin.conf:/bitcoin/bitcoin.conf \
   -p 127.0.0.1:8332:8332 \
   -p 8333:8333 \
   jamesob/bitcoind:0.20.1
```

### Building yourself

By default, the container runs under UID,GID=1000 to avoid executing as a privileged
user. If you want to rebuild the container with different settings, you can do so:

```
$ git clone https://github.com/jamesob/docker-bitcoind
$ cd docker-bitcoind
$ docker build -t $YOUR_USER/bitcoind:$SOME_VERSION \
   --build-arg UID=$(id -u) \
   --build-arg GID=$(id -g) \
   --build-arg VERSION=$SOME_VERSION \
   --build-arg SOURCE=release \
   .
```

To build an arbitrary git object:

```
$ ./bin/build-docker-bitcoin master
$ ./bin/build-docker-bitcoin v24.0rc2
$ ./bin/build-docker-bitcoin <some git object>
```

## Possible volume mounts

| Path | Description |
| ---- | ------- |
| `/bitcoin/data` | Bitcoin's data directory |
| `/bitcoin/bitcoin.conf` | Bitcoin's configuration file |



## Configuration

A custom `bitcoin.conf` file can be placed at `/bitcoin.conf`.
Otherwise, a default will be automatically generated based
on environment variables passed to the container:

| name | default |
| ---- | ------- |
| BTC_RPCUSER | btc |
| BTC_RPCPASSWORD | <randomly generated> |
| BTC_RPCPORT | 8332 |
| BTC_RPCBIND | 127.0.0.1 |
| BTC_RPCALLOWIP | ::/0 |
| BTC_RPCCLIENTTIMEOUT | 30 |
| BTC_DISABLEWALLET | 1 |
| BTC_TXINDEX | 0 |
| BTC_TESTNET | 0 |
| BTC_DBCACHE | 0 |
| BTC_ZMQPUBHASHTX | tcp://0.0.0.0:28333 |
| BTC_ZMQPUBHASHBLOCK | tcp://0.0.0.0:28333 |
| BTC_ZMQPUBRAWTX | tcp://0.0.0.0:28333 |
| BTC_ZMQPUBRAWBLOCK | tcp://0.0.0.0:28333 |


## Daemonizing

The smart thing to do if you're daemonizing is to use Docker's [builtin restart
policies](https://docs.docker.com/config/containers/start-containers-automatically/#use-a-restart-policy)
(i.e. `docker run --restart unless-stopped ...`), but if you're insistent on using
systemd, you could do something like

```bash
$ cat /etc/systemd/system/bitcoind.service

# bitcoind.service #######################################################################
[Unit]
Description=Bitcoind
After=docker.service
Requires=docker.service

[Service]
ExecStartPre=-/usr/bin/docker kill bitcoind
ExecStartPre=-/usr/bin/docker rm bitcoind
ExecStartPre=/usr/bin/docker pull jamesob/bitcoind
ExecStart=/usr/bin/docker run \
    --name bitcoind \
    -p 8333:8333 \
    -p 127.0.0.1:8332:8332 \
    -v /data/bitcoind:/root/.bitcoin \
    jamesob/bitcoind
ExecStop=/usr/bin/docker stop bitcoind
```

to ensure that bitcoind continues to run.
