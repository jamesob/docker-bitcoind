#!/usr/bin/env bash

set -e
# For debugging:
# set -x

# Versions available (per https://bitcoincore.org/bin) are:
#
# (there are earlier versions available, but the binary URLs don't conform to the
# same pattern.)
#

VERSIONS=(
0.13.0
0.13.1
0.13.2
0.14.3
0.15.2
0.16.3
0.17.0
0.17.0.1
0.17.1
0.17.2
0.18.0
0.18.1
0.19.0.1
0.19.1
0.20.0
0.20.1
0.20.2
0.21.0
0.21.1
0.21.2
22.0
23.0
)

err() {
  >&2 echo "$@"
}

if [ ! -f /etc/debian_version ] && [ ! -f /etc/lsb_release ]; then
  err "This script is intended for use on Debian-based systems."
  exit 1
fi

VERSION="$1"
INSTALL_PREFIX="${2:-/}"

URL_BASE="https://bitcoincore.org/bin/bitcoin-core-${VERSION}"
FILENAME="bitcoin-${VERSION}-x86_64-linux-gnu.tar.gz"

if [ -z "${VERSION}" ]; then
  err "Usage: get-bitcoin.sh <version> [<install-prefix>]"
  err
  err "Available versions are:"

  for v in "${VERSIONS[@]}"; do
    err "  ${v}"
  done

  err
  exit 1
fi

TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Verify signing key fingerprints here:
#
#   https://github.com/bitcoin/bitcoin/tree/master/contrib/builder-keys

curl -O "${URL_BASE}/SHA256SUMS.asc"
curl -O "${URL_BASE}/${FILENAME}"

if [[ "$VERSION" == "0."* ]]; then
  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 01EA5486DE18A882D4C2684590C8019E36C2E964
  sha256sum --ignore-missing --check SHA256SUMS.asc \
    | tee - | grep -o "${FILENAME}: OK"
  gpg --verify SHA256SUMS.asc >gpg_verify_out 2>&1
  grep '^gpg: Good signature from "Wladimir J. van der Laan' gpg_verify_out
  grep '^Primary key fingerprint: 01EA 5486 DE18 A882 D4C2  6845 90C8 019E 36C2 E964' gpg_verify_out
else
  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 71A3B16735405025D447E8F274810B012346C9A6
  curl -O "${URL_BASE}/SHA256SUMS"
  sha256sum --ignore-missing --check SHA256SUMS \
    | tee - | grep -o "${FILENAME}: OK"
  gpg --verify SHA256SUMS.asc SHA256SUMS >gpg_verify_out 2>&1 || true
  grep '^gpg: Good signature from "Wladimir J. van der Laan' gpg_verify_out
  grep '^Primary key fingerprint: 71A3 B167 3540 5025 D447  E8F2 7481 0B01 2346 C9A6' gpg_verify_out
fi

tar -xzvf "${FILENAME}"
DIR=$(find . -name 'bitcoin-*' -type d | head -n 1)
ls -lah ${DIR}
rm "${DIR}"/bin/bitcoin-qt
cp -r "${DIR}"/* "${INSTALL_PREFIX}"

echo
echo "Bitcoin installed:"
echo
"${INSTALL_PREFIX}/bin/bitcoind" --version || true
