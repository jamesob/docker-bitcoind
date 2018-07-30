#!/bin/bash

set -euo pipefail

BITCOIN_DIR=/root/.bitcoin
BITCOIN_CONF=${BITCOIN_DIR}/bitcoin.conf

# If config doesn't exist, initialize with sane defaults for running a
# non-mining node.

if [ ! -e "${BITCOIN_CONF}" ]; then
  tee -a >${BITCOIN_CONF} <<EOF

# For documentation on the config file, see
#
# the bitcoin source:
#   https://github.com/bitcoin/bitcoin/blob/master/contrib/debian/examples/bitcoin.conf
# the wiki:
#   https://en.bitcoin.it/wiki/Running_Bitcoin

# server=1 tells Bitcoin-Qt and bitcoind to accept JSON-RPC commands
server=1

# You must set rpcuser and rpcpassword to secure the JSON-RPC api
rpcuser=${BTC_RPCUSER:-btc}
rpcpassword=${BTC_RPCPASSWORD:-changemeplz}

# How many seconds bitcoin will wait for a complete RPC HTTP request.
# after the HTTP connection is established.
rpcclienttimeout=${BTC_RPCCLIENTTIMEOUT:-30}

rpcallowip=${BTC_RPCALLOWIP:-::/0}

# Listen for RPC connections on this TCP port:
rpcport=${BTC_RPCPORT:-8332}

# Print to console (stdout) so that "docker logs bitcoind" prints useful
# information.
printtoconsole=${BTC_PRINTTOCONSOLE:-1}

# We probably don't want a wallet.
disablewallet=${BTC_DISABLEWALLET:-1}

# Enable an on-disk txn index. Allows use of getrawtransaction for txns not in
# mempool.
txindex=${BTC_TXINDEX:-0}
testnet=${BTC_TESTNET:-0}
dbcache=${BTC_DBCACHE:-512}
zmqpubrawblock=${BTC_ZMQPUBRAWBLOCK:-tcp://0.0.0.0:28333}
zmqpubrawtx=${BTC_ZMQPUBRAWTX:-tcp://0.0.0.0:28333}
zmqpubhashtx=${BTC_ZMQPUBHASHTX:-tcp://0.0.0.0:28333}
zmqpubhashblock=${BTC_ZMQPUBHASHBLOCK:-tcp://0.0.0.0:28333}

EOF
fi

if [ $# -eq 0 ]; then
  exec bitcoind -datadir=${BITCOIN_DIR} -conf=${BITCOIN_CONF}
else
  exec "$@"
fi
