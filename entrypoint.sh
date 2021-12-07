#!/bin/bash

set -euo pipefail

export PATH=/usr/local/bin:$PATH

# See https://github.com/jamesob/docker-bitcoind/pull/16
sudo /usr/bin/append-to-hosts "$(ip -4 route list match 0/0 | awk '{print $3 "\thost.docker.internal"}')"

BITCOIN_DIR=/bitcoin/data
BITCOIN_CONF=/bitcoin/bitcoin.conf

if [ -z "${BTC_RPCPASSWORD:-}" ]; then
  # Provide a random password.
  BTC_RPCPASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 ; echo '')
fi

umask 077

# If config doesn't exist, initialize with sane defaults for running a
# non-mining node.

if [ ! -e "${BITCOIN_CONF}" ]; then
  tee -a >${BITCOIN_CONF} <<EOF

# For documentation on the config file, see
#
# the bitcoin source:
#   https://github.com/bitcoin/bitcoin/blob/master/share/examples/bitcoin.conf
# the wiki:
#   https://en.bitcoin.it/wiki/Running_Bitcoin

# server=1 tells Bitcoin-Qt and bitcoind to accept JSON-RPC commands
server=1

# You must set rpcuser and rpcpassword to secure the JSON-RPC api
rpcuser=${BTC_RPCUSER:-btc}
rpcpassword=${BTC_RPCPASSWORD}

# How many seconds bitcoin will wait for a complete RPC HTTP request.
# after the HTTP connection is established.
rpcclienttimeout=${BTC_RPCCLIENTTIMEOUT:-30}

rpcallowip=${BTC_RPCALLOWIP:-::/0}

# Listen for RPC connections on this TCP port:
rpcport=${BTC_RPCPORT:-8332}

# Bind to given address to listen for JSON-RPC connections.
# Refer to the manpage or bitcoind -help for further details.
rpcbind=${BTC_RPCBIND:-127.0.0.1}

# Print to console (stdout) so that "docker logs bitcoind" prints useful
# information.
printtoconsole=${BTC_PRINTTOCONSOLE:-1}

# We probably don't want a wallet.
disablewallet=${BTC_DISABLEWALLET:-1}

# Enable an on-disk txn index. Allows use of getrawtransaction for txns not in
# mempool.
txindex=${BTC_TXINDEX:-0}

# Run on the test network instead of the real bitcoin network.
testnet=${BTC_TESTNET:-0}

# Set database cache size in MiB
dbcache=${BTC_DBCACHE:-512}

# ZeroMQ notification options:
zmqpubrawblock=${BTC_ZMQPUBRAWBLOCK:-tcp://0.0.0.0:28333}
zmqpubrawtx=${BTC_ZMQPUBRAWTX:-tcp://0.0.0.0:28333}
zmqpubhashtx=${BTC_ZMQPUBHASHTX:-tcp://0.0.0.0:28333}
zmqpubhashblock=${BTC_ZMQPUBHASHBLOCK:-tcp://0.0.0.0:28333}

# [Sections]
# Most options apply to mainnet, testnet and regtest.
# If you want to confine an option to just one network, you should add it in the
# relevant section below.
# EXCEPTIONS: The options addnode, connect, port, bind, rpcport, rpcbind and wallet
# only apply to mainnet unless they appear in the appropriate section below.

# Options only for mainnet
[main]

# Options only for testnet
[test]

# Options only for regtest
[regtest]
EOF
echo "Created new configuration at ${BITCOIN_CONF}"
fi

chmod 0600 "${BITCOIN_CONF}"

if [ $# -eq 0 ]; then
  exec bitcoind -datadir=${BITCOIN_DIR} -conf=${BITCOIN_CONF}
else
  exec "$@"
fi
