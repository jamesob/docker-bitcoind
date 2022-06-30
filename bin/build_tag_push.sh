#!/bin/bash

set -eu

VERSIONS_ABOVE=${VERSIONS_ABOVE:-0.0}
VERSIONS=$(./bin/get-bitcoin.sh 2>&1 | grep '^  ' | tr -d '  ')

docker login docker.io

for ver in $VERSIONS; do

  if ! [[ "$ver" > "$VERSIONS_ABOVE" ]]; then
      echo "--- skipping version $ver"
      continue
  fi

  echo "--- building bitcoin $ver"
  echo
  echo
  docker build -t "jamesob/bitcoind:${ver}" --build-arg "VERSION=${ver}" .
  read -p "Push? (y/N): " confirm && [[ $confirm == [yY] ]] && \
  docker push "jamesob/bitcoind:${ver}" "docker://docker.io/jamesob/bitcoind:${ver}"
done
