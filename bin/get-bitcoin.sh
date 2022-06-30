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

set -x

TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Verify signing key fingerprints here:
#
#   https://github.com/bitcoin/bitcoin/tree/master/contrib/builder-keys

curl -O "${URL_BASE}/SHA256SUMS.asc"
curl -O "${URL_BASE}/${FILENAME}"

# In version 22.0, release signing changed from a single key signing in 
# SHA256SUMS.asc to multiple keys signing SHA256SUMS. 
#
# See here for more information: https://github.com/bitcoin/bitcoin/pull/23020

if [[ "$VERSION" < "22.0" ]]; then
  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 01EA5486DE18A882D4C2684590C8019E36C2E964
  sha256sum --ignore-missing --check SHA256SUMS.asc \
    | tee - | grep -o "${FILENAME}: OK"
  gpg --verify SHA256SUMS.asc >gpg_verify_out 2>&1
  grep '^gpg: Good signature from "Wladimir J. van der Laan' gpg_verify_out
  grep '^Primary key fingerprint: 01EA 5486 DE18 A882 D4C2  6845 90C8 019E 36C2 E964' gpg_verify_out

else
  # See bitcoin/contrib/builder-keys/keys.txt for current values.
  #
  # I've chosen a subset of builder keys here who are well-known and reliably 
  # sign for releases.

  # Wladimir
  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 71A3B16735405025D447E8F274810B012346C9A6
  # Hebasto
  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys D1DBF2C4B96F2DEBF4C16654410108112E7EA81F
  # Fanquake
  gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys E777299FC265DD04793070EB944D35F9AC3DB76A

  curl -O "${URL_BASE}/SHA256SUMS"
  gpg --verify SHA256SUMS.asc SHA256SUMS >gpg_verify_out 2>&1 || true
  cat gpg_verify_out

  grep '^gpg: Good signature from "Wladimir J. van der Laan' gpg_verify_out
  grep '^Primary key fingerprint: 71A3 B167 3540 5025 D447  E8F2 7481 0B01 2346 C9A6' gpg_verify_out

  grep '^gpg: Good signature from "Hennadii Stepanov' gpg_verify_out
  grep '^Primary key fingerprint: D1DB F2C4 B96F 2DEB F4C1  6654 4101 0811 2E7E A81F' gpg_verify_out

  grep '^gpg: Good signature from "Michael Ford' gpg_verify_out
  grep '^Primary key fingerprint: E777 299F C265 DD04 7930  70EB 944D 35F9 AC3D B76A' gpg_verify_out

  sha256sum --ignore-missing --check SHA256SUMS | tee - | grep -o "${FILENAME}: OK"
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
